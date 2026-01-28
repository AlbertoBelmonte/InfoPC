#Obtener la ruta del directorio del script actual

$rutaArchivo = "$PSScriptRoot\info.csv"
$existeArchivo = Test-Path $rutaArchivo

if (-Not $existeArchivo) {

    new-item -path $PSScriptRoot -Name "info.csv" -ItemType File | Out-Null

}

### DATOS GENERALES ###

$DataUnidadesRed = get-cimInstance win32_mappedlogicaldisk 
$DataImpresora = get-printer
$DataMonitores = Get-CimInstance -Namespace root\wmi WmiMonitorID
$DataChassis = get-ciminstance Win32_SystemEnclosure
$DataDiscos = Get-CimInstance Win32_DiskDrive
$DataUsers = Get-CimInstance Win32_UserAccount
$DataMoBo = get-ciminstance Win32_ComputerSystem
$DataGPU = Get-CimInstance Win32_VideoController
$DataRAM = Get-CimInstance Win32_PhysicalMemory
$DataOS = get-CimInstance Win32_OperatingSystem
$DataNIC = Get-NetAdapter | Sort-Object LinkSpeed -Descending

# Total Usuarios  

$ValidateUsers = ($DataUsers | Where-object { -not $_.Disabled }).Caption
$UsersLogIn = $ValidateUsers -join " / "

# Tipo de Equipo    

if ($DataChassis.ChassisTypes -match '8|9|10|14') {

    $TipoEquipo = "Portatil"

} elseif ($DataChassis.ChassisTypes -match '3|4|5|6|7') {

    $TipoEquipo = "Torre"

}

# GPU

$GPU = @()

foreach ($unit in $DataGPU){

    $GPU += "$($unit.Caption) $($unit.DriverDate) $($unit.DriverVersion)"

}        

$GPUs = $GPU -join " | "

# RAM (GB)    

$SlotRAM = @()

foreach ($modulo in $DataRAM) {

    $capacidad = [math]::Round($modulo.Capacity / 1GB, 2).ToString()
    $SlotRAM += "$capacidad GB $($modulo.Speed) MHz $($modulo.Manufacturer) $($modulo.PartNumber.trim())"

}

$RAM = $SlotRAM -join " | "

# Unidades de almacenamiento (internas)      

$Unidades = @()

foreach ($Disco in $DataDiscos) {

    $Particiones = Get-CimAssociatedInstance -InputObject $Disco -ResultClassName Win32_DiskPartition

    foreach ($Particion in $Particiones) {

        $DiscosLogicos = Get-CimAssociatedInstance -InputObject $Particion -ResultClassName Win32_LogicalDisk

        foreach ($LD in $DiscosLogicos) {

            $Nombre   = if ($LD.VolumeName) { $LD.VolumeName } else { "SinEtiqueta" }
            $Usados   = [math]::Round(($LD.Size - $LD.FreeSpace) / 1GB, 2)
            $Total    = [math]::Round($LD.Size / 1GB, 2)

            $Unidades += "$($LD.DeviceID) $Nombre $($Disco.Model) - $Usados GB / $Total GB"

        }
    }
}


$Disco = $Unidades -join " | "

# Unidades de red      

$UnidadesRed = @()

foreach ($unidad in $DataUnidadesRed){

    $UnidadesRed += $unidad.DeviceID + " " + $unidad.ProviderName

}

$DiscoRed = $UnidadesRed -join " | "

# Pantallas (Solo funciona en w11)    

$ModeloMonitor = @()

foreach ($monitor in $DataMonitores) {

    $model = ($monitor.UserFriendlyName | Where-Object { $_ -ne 0 }) -as [char[]]
    $ModeloMonitor += [string]::Join('', $model)

}

$Pantallas = $ModeloMonitor.trim() -join " | "

# Impresoras        

$ImpresorasValidas = @()

foreach ($impresora in $DataImpresora) {

    if ($impresora.Name -notmatch 'Microsoft|OneNote|Fax|AnyDesk|pdf'){ 

        $ImpresorasValidas += $impresora.Name

    }

}

$Impresoras = $ImpresorasValidas -join " | "


# NIC (nombre + IP + MAC)

$FullNIC = @()

foreach ($NIC in $DataNIC){

        $IPNIC = Get-NetIPAddress | Where-Object {$_.ifIndex -eq $NIC.ifIndex}
        $FullNIC += "$($NIC.InterfaceDescription) $($IPNIC.IpAddress) $($NIC.MacAddress) $($NIC.LinkSpeed)"

}

$NIC = $FullNIC -join " | "

# Sistema Operativo 

$OsVersion = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' DisplayVersion

$SO = "$($DataOS.Caption) $OsVersion Build: $($DataOS.BuildNumber)"

# Construir la informacion del sistema como un objeto personalizado

$infoSistema = [PSCustomObject]@{

        'Hostname'                    = $Env:COMPUTERNAME
        'Dominio'                     = $Env:LOGONSERVER       
        'Sistema Operativo'           = $SO
        'Fecha Instalacion OS'        = $DataOS.InstallDate
        'Usuario Actual'              = $Env:USERNAME
        'Total Usuarios'              = $UsersLogIn
        'Tipo de Equipo'              = $TipoEquipo
        'Fabricante'                  = $DataMoBo.Manufacturer
        'Modelo'                      = $DataMoBo.Model
        'Numero de Serie'             = (Get-CimInstance -Class Win32_BaseBoard).SerialNumber
        'CPU'                         = (Get-CimInstance -Classname Win32_Processor).Name
        'GPU'                         = $GPUs
        'RAM (GB)'                    = $RAM
        'Unidades de almacenamiento'  = $Disco
        'Unidades de red'             = $DiscoRed
        'NIC'                         = $NIC
        'Pantallas'                   = $Pantallas
        'Impresoras'                  = $Impresoras
        'Fecha datos'                 = Get-Date -Format "MM/dd/yyyy HH:mm" 

}

# Comprobar si se ha ejecutado 2 veces:

$LastLine = get-content -path $rutaArchivo -Tail 1
$CSVData = $infoSistema | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1

If ($LastLine -ne $CSVData) {

     if ($existeArchivo) {
        
        $infoSistema | Export-Csv -Path $rutaArchivo -Append -NoTypeInformation
        
     }else{
        
        $infoSistema | Export-Csv -Path $rutaArchivo -NoTypeInformation
        
     }
}
