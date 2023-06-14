# this script writen by mineshanya#1525, great thanks to dmf#5859 and gloomakaemphatic#5245, you can find us in Discord
# ===================================================================================================================================== #

#Requires -RunAsAdministrator

# ========================================= Configure this section below according to your PC ========================================= #

$DrovaIOServerApp = 'ese'

$MiningLauncherApp = 'NiceHashMiner'
$MiningLauncherPath = 'P:\Portable\Mining\NiceHash_Miner'

$MinerApp = 't-rex'
$MinerLaunchTimeoutMinutes = 5			# timeout for miner launching after Mining Launcher App started
$DAGGenTimeoutMinutes = 2 				# timeout for miner to generate DAG file, 30 seconds are usually enough

$AfterburnerPath = 'C:\Program Files (x86)\MSI Afterburner'
$MiningProfile = '-Profile4'
$MiningProfileShifted = '-Profile5'		# it's just a copy of MiningProfile only with next memory clock step (e.g. 5760 and 5764)


$PillApp = 'OhGodAnETHlargementPill-r2' # no need in ----revA option!
$PillPath = 'P:\Portable\Mining\OhGodAnETHlargementPill-master'

# ===================================================================================================================================== #
# primitive check if there is no load on GPU
function Check-GPUIsIdle {
	$GPUUsage = [int](nvidia-smi dmon -c 1 -s u)[2].substring(8,3)		# in %
	$FBUsage = [int](nvidia-smi dmon -c 1 -s u)[2].substring(14,3)		# in %
	$GPUMemUsage = [int](nvidia-smi dmon -c 1 -s m)[2].substring(7,4)	# in Mb
	# Sometimes nvidia-smi may show small load when actualy there is no any, so just increase a bit values below
	if (($GPUUsage -le 20) -and ($FBUsage -le 20) -and ($GPUMemUsage -le 1500)) {
		return $True
	} else {
		return $False
	}
}

# primitive check if there is load on GPU similar to mining
function Check-GPUIsMining {
	$GPUUsage = [int](nvidia-smi dmon -c 1 -s u)[2].substring(8,3)		# in %
	$FBUsage = [int](nvidia-smi dmon -c 1 -s u)[2].substring(14,3)		# in %
	$GPUMemUsage = [int](nvidia-smi dmon -c 1 -s m)[2].substring(7,4)	# in Mb
	if (($GPUUsage -ge 90) -and ($FBUsage -ge 60) -and ($GPUMemUsage -ge 5000)) {
		return $True
	} else {
		return $False
	}
}

# finds corresponding to local maximum profile through FBUsage, runs when mining already started
function Set-CorrectAfterburnerProfile {
	Write-Host "Finding local maximum..."
	$FBUsage1 = 0
	$FBUsage2 = 0
	Start-Process -FilePath 'MSIAfterburner.exe' -WorkingDirectory $AfterburnerPath -ArgumentList $MiningProfile
	for (($i = 0); $i -lt 3; $i++) {
		Start-Sleep -s 2
		$FBUsage1 += [int](nvidia-smi dmon -c 1 -s u)[2].substring(14,3)
	}
	Start-Process -FilePath 'MSIAfterburner.exe' -WorkingDirectory $AfterburnerPath -ArgumentList $MiningProfileShifted
	for (($i = 0); $i -lt 3; $i++) {
		Start-Sleep -s 2
		$FBUsage2 += [int](nvidia-smi dmon -c 1 -s u)[2].substring(14,3)
	}
	if ($FBUsage1 -gt $FBUsage2) {
		Write-Host "$MiningProfile is local maximum"
		Start-Process -FilePath 'MSIAfterburner.exe' -WorkingDirectory $AfterburnerPath -ArgumentList $MiningProfile
	} else {
		Write-Host "$MiningProfileShifted is local maximum"
		Start-Process -FilePath 'MSIAfterburner.exe' -WorkingDirectory $AfterburnerPath -ArgumentList $MiningProfileShifted
	}
	if ($FBUsage1 -eq $FBUsage2) {
		Write-Host "Ooops! Both profiles showed same performance"
		return 0
	}
}

# launch pill according to FB usage, accurate only if there is no other load on GPU
function Start-Pill {
	if ((Set-CorrectAfterburnerProfile) -eq 0) { return 0 }
	Write-Host "Starting Pill"
	Start-Process -FilePath $($PillApp+'.exe') -WorkingDirectory $PillPath
}

if (!(Get-Process $MiningLauncherApp -ErrorAction SilentlyContinue)) {
	if (!(Get-Process $DrovaIOServerApp -ErrorAction SilentlyContinue)) {
		if (Check-GPUIsIdle -eq $True) {
			Write-Host "Miner and drova.io Server are not running, starting mining..."
			Start-Process -FilePath $($MiningLauncherApp+'.exe') -WorkingDirectory $MiningLauncherPath
			$TimerMiner = [Diagnostics.Stopwatch]::StartNew()
			while ((!(Get-Process $MinerApp -ErrorAction SilentlyContinue)) -and ($TimerMiner.elapsed.totalminutes -lt $MinerLaunchTimeoutMinutes)) {
				Write-Host "Waiting for t-rex..."
				Start-Sleep -s 10
			}
			$TimerMiner.stop()
			$TimerDAGGen = [Diagnostics.Stopwatch]::StartNew()
			if (Get-Process $MinerApp -ErrorAction SilentlyContinue) {
				while ((!(Check-GPUIsMining)) -and ($TimerMiner.elapsed.totalminutes -lt $DAGGenTimeoutMinutes)) {
					Write-Host "Waiting for t-rex to generate DAG..."
					Start-Sleep -s 10
				}
				$TimerDAGGen.stop()
				if ((Start-Pill) -eq 0)  { Write-Host "Pill failed to start!" }
			} else {
				Write-Host "Timeout! t-rex was not launched!"
			}
		} else {
			Write-Host "There is some 3D load on GPU, stop it first"
		}
	}
} else {
	if (!(Get-Process $MinerApp -ErrorAction SilentlyContinue)) {
		Write-Host "Miner has stopped, restarting Miner Launcher App"
		Taskkill /IM app_nhm.exe
		Start-Sleep -s 5
		Start-Process -FilePath $($MiningLauncherApp+'.exe') -WorkingDirectory $MiningLauncherPath
	} else {
		Write-Host "Miner already running"
	}
}