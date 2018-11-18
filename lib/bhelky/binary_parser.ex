defmodule Bhelky.BinaryParser do
  use Bitwise, only_operators: true

  @opcodes %{
    #0   => :nop,
    14  => :out,
    15  => :hlt
  }

  @arg_opcodes %{
    1   => :lda,
    2   => :add,
    3   => :sub,
    4   => :sta,
    5   => :ldi,
    6   => :jmp,
    7   => :jc,
    8   => :jz,
    9   => :jnc,
  }

  def parse(path) do
    {:ok, file} = File.open(path)

    file
    |> IO.binstream(1)
    |> Enum.map(&decode/1)
    |> Enum.map(&translate/1)
  end

  # Decode byte into left and right 4 bit pieces
  defp decode(bitstring) do
    <<opcode :: size(4), arg :: size(4)>> = bitstring
    { opcode, arg }
  end

  # Just return data
  defp translate({0, x}) do
    x
  end
  defp translate({opcode, arg}) do
    case Map.fetch(@opcodes, opcode) do
      {:ok, result} ->
        {result}
      _ ->
        case Map.fetch(@arg_opcodes, opcode) do
          {:ok, result} ->
            {result, arg}
          _ ->
            raise ArgumentError, message: "Unknown operation #{inspect {opcode, arg}}"
        end
    end
  end
end
