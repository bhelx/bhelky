defmodule Bhelky.CLI do
	def main(args \\ []) do
    args
    |> parse_args
    |> IO.puts()
  end

  defp parse_args(["assemble" | args]) do
    {opts, _, _} =
      args
      |> OptionParser.parse(switches: [input: :string, output: :string])

    case opts do
      [input: input, output: output] ->
        case Bhelky.Assembler.assemble(input, output) do
          :ok -> "Binary written to #{output}"
          {:error, reason} -> "Could not assemble with options #{inspect opts}: Message: #{reason}"
        end
      _ ->
        "Options not valid #{inspect opts}"
    end
  end
  defp parse_args(["emulate" | args]) do
    {opts, _, _} =
      args
      |> OptionParser.parse(switches: [
        input: :string,
        slowdown: :integer,
        history: :string
      ])

    case opts do
      [input: input, slowdown: slowdown, history: hfile] ->
        input
        |> Bhelky.BinaryParser.parse
        |> Bhelky.Machine.new
        |> Bhelky.Machine.run(slowdown)
        |> Bhelky.Machine.store_execution_history(hfile)
        |> List.last
        |> inspect
      _ ->
        "Options not valid #{inspect opts}"
    end
  end
  defp parse_args(args) do
    raise ArgumentError, message: "Unknown command #{inspect args}"
  end
end
