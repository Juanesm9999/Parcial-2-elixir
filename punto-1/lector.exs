defmodule Lector do
  @moduledoc """
  Lectura de archivos: lee un archivo y separa los registros válidos de los rechazados.
  """

  # Devuelve {:ok, {registros_validos, cantidad_rechazados}} o {:error, razon}
  def leer_archivo(ruta, convertidor) do
    case File.read(ruta) do
      {:ok, contenido} ->
        resultado =
          contenido
          |> String.split("\n")
          |> procesar_lineas(convertidor, [], 0)

        {:ok, resultado}

      {:error, razon} ->
        {:error, razon}
    end
  end

  # caso base: no quedan líneas
  defp procesar_lineas([], _convertidor, validos, rechazados) do
    {Enum.reverse(validos), rechazados}
  end

  # caso recursivo: procesa la primera línea y continúa con el resto
  defp procesar_lineas([linea | resto], convertidor, validos, rechazados) do
    texto = String.trim(linea)

    if texto == "" do
      procesar_lineas(resto, convertidor, validos, rechazados)
    else
      case convertidor.(texto) do
        {:ok, registro} -> procesar_lineas(resto, convertidor, [registro | validos], rechazados)
        :error -> procesar_lineas(resto, convertidor, validos, rechazados + 1)
      end
    end
  end
end
