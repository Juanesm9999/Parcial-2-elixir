defmodule Reporte do
  @moduledoc """
  Cálculo del reporte: estadísticas por ciudad y texto del reporte.
  """

  # ---------- Reporte general (todas las ciudades) ----------
  def generar_general(datos) do
    {movimientos, sin_ciudad} = separar_movimientos(datos)

    detalle =
      datos.ciudades
      |> Enum.map(fn ciudad -> texto_ciudad(ciudad, movimientos) end)
      |> Enum.join("\n")

    "REPORTE DE SISMOS POR CIUDAD\n" <>
      linea_separadora() <>
      detalle <>
      "\n" <>
      texto_rechazados(datos.rechazados_ciudades, datos.rechazados_movimientos + sin_ciudad)
  end

  # ---------- Reporte de una ciudad ----------
  def generar_ciudad(datos, id_ciudad) do
    {movimientos, _sin_ciudad} = separar_movimientos(datos)

    case Enum.find(datos.ciudades, fn ciudad -> ciudad.id == id_ciudad end) do
      nil -> "La ciudad no está registrada"
      ciudad -> "REPORTE DE LA CIUDAD #{id_ciudad}\n" <> linea_separadora() <> texto_ciudad(ciudad, movimientos)
    end
  end

  # Los movimientos cuya ciudad no existe en el catálogo se rechazan
  defp separar_movimientos(datos) do
    ids = Enum.map(datos.ciudades, fn ciudad -> ciudad.id end)

    {validos, sin_ciudad} =
      Enum.split_with(datos.movimientos, fn movimiento -> Enum.member?(ids, movimiento.id_ciudad) end)

    {validos, length(sin_ciudad)}
  end

  # ---------- Recursividad explícita: un solo recorrido ----------
  # Devuelve {cantidad, movimiento_mayor_magnitud, suma_profundidades}
  def calcular_estadisticas(movimientos), do: calcular_estadisticas(movimientos, 0, nil, 0.0)

  # caso base: no quedan movimientos
  defp calcular_estadisticas([], cantidad, mayor, suma), do: {cantidad, mayor, suma}

  # caso recursivo: actualiza los tres acumuladores y continúa con el resto
  defp calcular_estadisticas([movimiento | resto], cantidad, mayor, suma) do
    calcular_estadisticas(resto, cantidad + 1, elegir_mayor(mayor, movimiento), suma + movimiento.profundidad)
  end

  # Con > estricto, ante un empate se conserva el primero que aparece en el archivo
  defp elegir_mayor(nil, movimiento), do: movimiento

  defp elegir_mayor(mayor, movimiento) do
    if movimiento.magnitud > mayor.magnitud, do: movimiento, else: mayor
  end

  # ---------- Texto ----------
  defp texto_ciudad(ciudad, movimientos) do
    movimientos_ciudad = Enum.filter(movimientos, fn movimiento -> movimiento.id_ciudad == ciudad.id end)
    {cantidad, mayor, suma} = calcular_estadisticas(movimientos_ciudad)

    "Ciudad: #{ciudad.nombre} (#{ciudad.id})\n" <>
      "Habitantes: #{ciudad.habitantes}\n" <>
      texto_movimientos(movimientos_ciudad) <>
      "Total de movimientos: #{cantidad}\n" <>
      "Movimiento de mayor magnitud: #{texto_mayor(mayor)}\n" <>
      "Profundidad promedio: #{texto_promedio(cantidad, suma)}\n" <>
      linea_separadora()
  end

  defp texto_movimientos([]), do: "Movimientos: Sin movimientos registrados\n"

  defp texto_movimientos(movimientos) do
    detalle =
      movimientos
      |> Enum.map(fn m ->
        "  #{m.codigo} | inicio #{m.hora_inicio} | final #{m.hora_final} | magnitud #{m.magnitud} | profundidad #{m.profundidad} km"
      end)
      |> Enum.join("\n")

    "Movimientos:\n" <> detalle <> "\n"
  end

  defp texto_mayor(nil), do: "No aplica"
  defp texto_mayor(movimiento), do: "#{movimiento.codigo} · #{movimiento.magnitud}"

  defp texto_promedio(0, _suma), do: "No aplica"
  defp texto_promedio(cantidad, suma), do: "#{dos_decimales(suma / cantidad)} km"

  defp dos_decimales(numero), do: :erlang.float_to_binary(numero, decimals: 2)

  defp texto_rechazados(rechazados_ciudades, rechazados_movimientos) do
    "Registros rechazados:\n" <>
      "  ciudades.txt: #{rechazados_ciudades}\n" <>
      "  movimientos.txt: #{rechazados_movimientos}"
  end

  defp linea_separadora(), do: "--------------------------------------------------\n"
end
