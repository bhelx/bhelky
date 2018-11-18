defmodule Bhelky.Assembler do
  def assemble(input_file, output_file) do
    case System.cmd("customasm", [input_file, "-o", output_file]) do
      {_result, 0} -> :ok
      {result, _} -> {:error, result}
    end
  end
end
