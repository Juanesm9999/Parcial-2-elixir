defmodule Coordinador do
  @moduledoc """
  Coordinación de procesos: inicia dos trabajadores (spawn), uno por archivo,
  y espera sus respuestas (receive) en cualquier orden.
  """
  @ruta_ciudades "resources/ciudades.txt"
  @ruta_movimientos "resources/movimientos.txt"

  # Devuelve {:ok, datos} o {:error, mensaje}
  def obtener_datos() do
    coordinador = self()

    # primero se inician ambos trabajadores
    iniciar_trabajador(coordinador, :ciudades, @ruta_ciudades, &Ciudad.convertir_linea/1)
    iniciar_trabajador(coordinador, :movimientos, @ruta_movimientos, &Movimiento.convertir_linea/1)

    # Después se esperan las dos respuestas
    %{}
    |> recibir_resultados()
    |> validar_resultados()
  end

  defp iniciar_trabajador(coordinador, archivo, ruta, convertidor) do
    spawn(fn ->
      resultado = Lector.leer_archivo(ruta, convertidor)
      send(coordinador, {:resultado_archivo, archivo, ruta, resultado})
    end)
  end

  # caso base: ya llegaron las respuestas de los dos archivos
  defp recibir_resultados(resultados) when map_size(resultados) == 2, do: resultados

  # caso recursivo: acepta la respuesta que llegue primero
  defp recibir_resultados(resultados) do
    receive do
      {:resultado_archivo, archivo, ruta, resultado} ->
        resultados
        |> Map.put(archivo, {ruta, resultado})
        |> recibir_resultados()
    end
  end

  defp validar_resultados(%{
         ciudades: {_, {:ok, {ciudades, rechazadas}}},
         movimientos: {_, {:ok, {movimientos, rechazados}}}
       }) do
    {:ok,
     %{
       ciudades: ciudades,
       movimientos: movimientos,
       rechazados_ciudades: rechazadas,
       rechazados_movimientos: rechazados
     }}
  end

  defp validar_resultados(resultados) do
    mensaje =
      resultados
      |> Map.values()
      |> Enum.filter(fn {_ruta, resultado} -> resultado_con_error?(resultado) end)
      |> Enum.map(fn {ruta, {:error, razon}} -> "No se pudo leer el archivo #{ruta} (#{razon})" end)
      |> Enum.join("\n")

    {:error, mensaje}
  end

  defp resultado_con_error?({:error, _razon}), do: true
  defp resultado_con_error?(_resultado), do: false
end
