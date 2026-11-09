defmodule Ciudad do
  @enforce_keys [:id, :nombre, :habitantes]
  defstruct [:id, :nombre, :habitantes]
  # id, nombre: String
  #habitantes: entero

  def crear(id, nombre, habitantes) do
    %Ciudad{id: id, nombre: nombre, habitantes: habitantes}
  end

  # Convierte una línea del archivo en {:ok, ciudad} o :error (registro rechazado)
  def convertir_linea(linea) do
    case String.split(linea, "@") do
      [id, nombre, habitantes] ->
        validar(String.trim(id), String.trim(nombre), String.trim(habitantes))

      _ ->
        :error
    end
  end

  defp validar(id, nombre, habitantes) do
    numero_habitantes = convertir_entero(habitantes)

    cond do
      id == "" or nombre == "" or habitantes == "" -> :error
      numero_habitantes == nil -> :error
      numero_habitantes <= 0 -> :error
      true -> {:ok, crear(id, nombre, numero_habitantes)}
    end
  end

  # Devuelve el entero o nil si el texto no es un entero válido
  defp convertir_entero(texto) do
    case Integer.parse(texto) do
      {numero, ""} -> numero
      _ -> nil
    end
  end
end

defmodule Movimiento do
  @enforce_keys [:codigo, :id_ciudad, :hora_inicio, :hora_final, :magnitud, :profundidad]
  defstruct [:codigo, :id_ciudad, :hora_inicio, :hora_final, :magnitud, :profundidad]
  # codigo, id_ciudad: String
  # hora_inicio, hora_final: Time
  # magnitud, profundidad: float

  def crear(codigo, id_ciudad, hora_inicio, hora_final, magnitud, profundidad) do
    %Movimiento{
      codigo: codigo,
      id_ciudad: id_ciudad,
      hora_inicio: hora_inicio,
      hora_final: hora_final,
      magnitud: magnitud,
      profundidad: profundidad
    }
  end

  # Convierte una línea del archivo en {:ok, movimiento} o :error (registro rechazado)
  def convertir_linea(linea) do
    campos =
      linea
      |> String.split("@")
      |> Enum.map(&String.trim/1)

    case campos do
      [codigo, id_ciudad, hora_inicio, hora_final, magnitud, profundidad] ->
        validar(codigo, id_ciudad, hora_inicio, hora_final, magnitud, profundidad)

      _ ->
        :error
    end
  end

  defp validar(codigo, id_ciudad, hora_inicio, hora_final, magnitud, profundidad) do
    valor_inicio = convertir_hora(hora_inicio)
    valor_final = convertir_hora(hora_final)
    valor_magnitud = convertir_decimal(magnitud)
    valor_profundidad = convertir_decimal(profundidad)

    cond do
      codigo == "" or id_ciudad == "" -> :error
      valor_inicio == nil or valor_final == nil -> :error
      valor_magnitud == nil -> :error
      valor_profundidad == nil -> :error
      valor_profundidad < 0 -> :error
      true -> {:ok, crear(codigo, id_ciudad, valor_inicio, valor_final, valor_magnitud, valor_profundidad)}
    end
  end

  # Convierte "HH:MM:SS" en un Time; devuelve nil si no es una hora del día válida
  defp convertir_hora(texto) do
    case Time.from_iso8601(texto) do
      {:ok, hora} -> if String.length(texto) == 8, do: hora, else: nil
      {:error, _razon} -> nil
    end
  end

  # Devuelve el número decimal o nil si el texto no se puede convertir
  defp convertir_decimal(texto) do
    case Float.parse(texto) do
      {numero, ""} -> numero
      _ -> nil
    end
  end
end
