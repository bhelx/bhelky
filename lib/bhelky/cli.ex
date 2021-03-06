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
          :ok ->
            "Binary written to #{output}"

          {:error, reason} ->
            "Could not assemble with options #{inspect(opts)}: Message: #{reason}"
        end

      _ ->
        "Options not valid #{inspect(opts)}"
    end
  end

  defp parse_args(["emulate" | args]) do
    {opts, _, _} =
      args
      |> OptionParser.parse(
        switches: [
          input: :string,
          slowdown: :integer,
          history: :string
        ]
      )

    case opts do
      [input: input, slowdown: slowdown, history: hfile] ->
        input
        |> Bhelky.BinaryParser.parse()
        |> Bhelky.Machine.new()
        |> Bhelky.Machine.run(slowdown)
        |> Bhelky.Machine.store_execution_history(hfile)
        |> List.last()
        |> inspect

      _ ->
        "Options not valid #{inspect(opts)}"
    end
  end

  defp parse_args(["display" | args]) do
    {opts, _, _} =
      args
      |> OptionParser.parse(switches: [input: :string])

    case opts do
      [input: input] ->
        input
        |> File.stream!([], 1)
        |> Stream.with_index()
        |> Enum.map(fn {v, idx} ->
          <<opcode::size(4), arg::size(4)>> = v
          "#{to_4_bit(idx)} => #{to_4_bit(opcode)} | #{to_4_bit(arg)}\n"
        end)
      _ ->
        "Options not valid #{inspect(opts)}"
    end
  end

  defp parse_args(args) do
    raise ArgumentError, message: "Unknown command #{inspect(args)}"
  end

  defp to_4_bit(n) do
    n
    |> Integer.to_string(2)
    |> String.pad_leading(4, "0")
  end
end
