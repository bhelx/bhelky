defmodule Bhelky.Machine do
  defstruct [
    carry_bit: false,
    reg_a: 0,
    reg_b: 0,
    reg_o: 0,
    pc: 0,
    memory: [],
  ]

  def new(program) do
    %Bhelky.Machine{
      memory: right_pad(program)
    }
  end

  def run(machine, slowdown \\ 0, history \\ []) do
    history = cond do
      length(history) == 0 -> [{nil, machine}]
      true -> history
    end
    :timer.sleep(slowdown)
    instr = Enum.at(machine.memory, machine.pc)
    #IO.puts("[#{machine.pc}] #{inspect instr} #{machine.reg_a} #{inspect machine.memory}")
    case exec(machine, instr) do
      nil -> history ++ [{instr, machine}]
      m -> run(m, slowdown, history ++ [{instr, m}])
    end
  end

  def fetch(machine, addr) do
    Enum.at(machine.memory, addr)
  end

  def load(machine, reg, val) do
    %{machine | reg => val}
  end

  def store(machine, addr, val) do
    %{machine | memory: List.replace_at(machine.memory, addr, val)}
  end

  def incr(machine) do
    %{machine | pc: machine.pc + 1}
  end

  # HALT - stop the machine
  def exec(_machine, {:hlt}) do
    nil
  end

  # NOP - do nothing
  def exec(machine, {:nop}) do
    machine
  end

  # OUT - display contents of register A
  # Also prints to terminal
  def exec(machine, {:out}) do
    IO.puts("Out [#{machine.reg_a}]")
    load(machine, :reg_o, machine.reg_a) |> incr
  end

  # LDA X - load memory contents at address X into register A
  def exec(machine, {:lda, addr}) do
    load(machine, :reg_a, fetch(machine, addr)) |> incr
  end

  # LDB X - load memory contents at address X into register B
  def exec(machine, {:ldb, addr}) do
    load(machine, :reg_b, fetch(machine, addr)) |> incr
  end

  # LDI X - load the value X into register A
  def exec(machine, {:ldi, val}) do
    load(machine, :reg_a, val) |> incr
  end

  # STA X - store the contents of register A into address X
  def exec(machine, {:sta, addr}) do
    store(machine, addr, machine.reg_a) |> incr
  end

  # JMP C - jump to program location C
  def exec(machine, {:jmp, pc}) do
    %{machine | pc: pc}
  end

  # JZ C - jump to program location C if A - B == zero
  #        else just move on in the program
  def exec(machine, {:jz, pc}) do
    if machine.reg_a - machine.reg_b == 0 do
      %{machine | pc: pc}
    else
      incr(machine)
    end
  end

  # JC C - jump to program location C if carry bit is set
  #        else just move on in the program
  def exec(machine, {:jc, pc}) do
    if machine.carry_bit do
      %{machine | pc: pc}
    else
      incr(machine)
    end
  end

  # JNC C - jump to program location C if carry bit is NOT set
  #         else just move on in the program
  def exec(machine, {:jnc, pc}) do
    unless machine.carry_bit do
      %{machine | pc: pc}
    else
      incr(machine)
    end
  end

  # ADD X - put memory contents at address X into register B
  #         then sum and put result into register A
  def exec(machine, {:add, addr}) do
    v = fetch(machine, addr)
    machine
    |> load(:reg_b, v)
    |> load(:reg_a, machine.reg_a + v)
    |> Map.put(:carry_bit, machine.reg_a + v > 255)
    |> incr
  end

  # SUB X - put memory contents at address X into register B
  #         then subtract and put result into register A
  def exec(machine, {:sub, addr}) do
    v = fetch(machine, addr)
    machine
    |> load(:reg_b, v)
    |> load(:reg_a, machine.reg_a - v)
    |> incr
  end

  # Breakpoint
  def exec(machine, {:break, instr}) do
    require IEx; IEx.pry
    exec(machine, instr)
  end

  def exec(machine, instr) do
    raise ArgumentError, message: "Unknown instruction: #{inspect instr}. Machine: #{inspect machine}"
  end

  def store_execution_history(history, path) do
    {:ok, file} = File.open(path, [:write])
    IO.binwrite file, :erlang.term_to_binary(history)
    File.close(file)
    history
  end

  def load_execution_history(path) do
    {:ok, file} = File.open(path)
    history = :erlang.binary_to_term(IO.binread(file, :all))
    File.close(file)
    history
  end

  defp right_pad(program) when length(program) < 16 do
    right_pad(program ++ [0])
  end
  defp right_pad(program) do
    program
  end
end
