# InfoPC
Script en powershell que genera un csv y recopila la siguiente informacion del equipo:

- Hostname
- Dominio
- Sistema Operativo
- Fecha Instalacion OS
- Usuario Actual
- Total Usuarios
- Tipo de Equipo
- Fabricante
- Modelo
- Numero de Serie
- CPU
- GPU
- RAM (GB)
- Unidades de almacenamiento
- Unidades de red
- NIC
- Pantallas
- Impresoras
- Fecha datos

Windows necesita tener firmado el .ps1 para poder ejecutarlo en powershell, para hacer una prueba rapida se puede desactivar la directiva con este comando:

```powershell
Set-ExecutionPolicy Unrestricted
```

Para activar de nuevo la restricción: 

```powershell
Set-ExecutionPolicy RemoteSigned
```
