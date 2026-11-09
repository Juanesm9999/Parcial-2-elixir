Code.require_file("util.exs")
Code.require_file("structs.exs")
Code.require_file("lector.exs")
Code.require_file("coordinador.exs")
Code.require_file("reporte.exs")

defmodule ReporteSismos do
  @ruta_reporte "resources/reporte_sismos.txt"

  def main do
    Coordinador.obtener_datos()
    |> generar_reporte()
  end

  defp generar_reporte({:ok, datos}) do
    reporte = Reporte.generar_general(datos)

    reporte
    |> Util.mostrar_mensaje()

    reporte
    |> guardar_reporte()
  end

  # Si algún archivo no se pudo leer, se informa y se conserva el reporte anterior
  defp generar_reporte({:error, mensaje}) do
    mensaje
    |> Util.mostrar_error()
  end

  defp guardar_reporte(reporte) do
    case File.write(@ruta_reporte, reporte) do
      :ok -> Util.mostrar_mensaje("\nReporte guardado en #{@ruta_reporte}")
      {:error, razon} -> Util.mostrar_error("No se pudo guardar el reporte en #{@ruta_reporte} (#{razon})")
    end
  end
end

ReporteSismos.main()
