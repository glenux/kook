
kotam_run() {
	local cmd="$*"
	qdbus org.kde.konsole /Sessions/${session} sendText "$cmd"
	qdbus org.kde.konsole /Sessions/${session} sendText "
	"
}


kotam_newtab() {
	#dbus-send --session --dest=${KONSOLE_DBUS_SERVICE} --type=method_call \
	#	--print-reply /konsole/MainWindow_1 org.kde.KMainWindow.activateAction string:"new-tab"

	session=$(qdbus org.kde.konsole /Konsole newSession)
}

kotam_renametab() {
	#sessionno=$1
	tabname=$1
	#session="/Sessions/${sessionno}"
	#dbus-send --session --dest=${KONSOLE_DBUS_SERVICE} --type=method_call --print-reply ${session} org.kde.konsole.Session.setTitle int32:1 string:"$tabname"
	qdbus org.kde.konsole /Sessions/${session} setTitle 1 "$tabname"
}

