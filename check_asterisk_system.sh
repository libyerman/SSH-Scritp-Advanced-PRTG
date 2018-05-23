#!/bin/bash
#
# Scritp para PRTG Sensor SSH Advanced 
# German Hurtado


ASTERISK=/usr/sbin/asterisk


print_usage() {
    echo "
Usage: check_asterisk_system.sh [--type | -t <sip|iax>] [--peers | -p <peers>] [--registrations | -r <registrations>] 
Usage: check_asterisk_system.sh --help | -h

Descripcion:

script para PRTG que devuelve valores de Disco, CPU, SWAP, Interfaces de red. Puedes monitorizar de forma opcional
troncales extensiones etc... usando las opciones.


Acepta las siguientes opciones

  --psip  | --peers-sip            (Opcional) Lista de peers SIP a chequear.
                                   Usar con valores entre comillas separados por espacios

  --piax  | --peers-iax            (Opcional) Lista de peers IAX a chequear.
                                   Usar con valores entre comillas separados por espacios
                          
  --registrationssip  | -rsip      (Opcional) Lista de usuarios SIP registrados a chequear.
                                   Usar con valores entre comillas separados por espacios

  --registrationsiax  | -riax      (Opcional) Lista de usuarios SIP registrados a chequear.
                                   Usar con valores entre comillas separados por espacios

  --descripcion  | -d              (Opcional) Descricion que mostrara en el sensor.
                                   Usar con valores entre comillas separados por espacios

  --help | -h                      Muestra la ayuda del script.

Ejemplos:

  check_asterisk_system.sh -psip \"foo bar\"
  check_asterisk_system.sh -psip \"foo bar\" -rsip \"ufoo ubar\"


"
}

print_help() {
    print_usage
    echo "Script que muestra estado de la máquina asterisk y devuelve un XML válido para PRTG SSH script advanced."
    echo ""
}


# Grab the command line arguments.
while test -n "$1"; do
    case "$1" in
        --help)
            print_help
            exit $STATE_OK
            ;;
        -h)
            print_help
            exit $STATE_OK
            ;;
        --peers-sip)
            peerssip=$2
            shift
            ;;
        -psip)
            peerssip=$2
            shift
            ;;
        --peers-iax)
            peersiax=$2
            shift
            ;;
        -piax)
            peersiax=$2
            shift
            ;;
         --registrations-sip)
            registrationssip=$2
            shift
            ;;
         -rsip)
            registrationssip=$2
            shift
            ;;
         --registrations-iax)
            registrationsiax=$2
            shift
            ;;
         -riax)
            registrationsiax=$2
            shift
            ;;
         -d)
            descripcion=$2
            shift
            ;;
         --descripcion)
            descripcion=$2
            shift
            ;;
        *)
            echo "Parametro desconocido: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
    esac
    shift
done 


# Sip peers.
if [ "$peerssip" ]; then
        for p in $peerssip
        do
		command_output=`sudo $ASTERISK -rx "sip show peer $p" 2>&1`

        	latencia=`echo "$command_output" | grep "^[[:space:]]*Status[[:space:]]*:" | awk '{print $4;}' | awk '{print $1;}' |sed -e 's/^(//' -e 's/;$//'`


		if [ "$latencia" -gt 0 ] && [ "$latencia" -lt 2000 ]; then
			test_lt=`echo $latencia`
		else
			test_lt=0
		fi

                xml_troncales=" $xml_troncales 
                <result>
                <channel>$p</channel>
                <unit>TimeResponse</unit>
                <mode>Absolute</mode>
                <float>1</float>
                <limitMode>1</limitMode>
                <limitMaxWarning>1000</limitMaxWarning>
                <limitMaxError>1999</limitMaxError>
                <limitMinWarning>1</limitMinWarning>
                <limitMinError>1</limitMinError>
                <limitErrorMsg>Error troncal SIP</limitErrorMsg>at>
                <value>$test_lt</value>
                </result>
                "

        done
fi

# IAX peers.
if [ "$peersiax" ]; then
        for p in $peersiax
        do
                command_output=`sudo $ASTERISK -rx "iax2 show peer $p" 2>&1`

                latencia=`echo "$command_output" | grep "^[[:space:]]*Status[[:space:]]*:" | awk '{print $4;}' | awk '{print $1;}' |sed -e 's/^(//' -e 's/;$//'`


                if [ "$latencia" -gt 0 ] && [ "$latencia" -lt 2000 ]; then
                        test_lt=`echo $latencia`
                else
                        test_lt=0
                fi

                xml_troncales=" $xml_troncales 
                <result>
                <channel>$p</channel>
                <unit>TimeResponse</unit>
                <mode>Absolute</mode>
                <float>1</float>
                <limitMode>1</limitMode>
                <limitMaxWarning>1000</limitMaxWarning>
                <limitMaxError>1999</limitMaxError>
                <limitMinWarning>1</limitMinWarning>
                <limitMinError>1</limitMinError>
                <limitErrorMsg>Error troncal IAX</limitErrorMsg>             
                <value>$test_lt</value>
                </result>
                "

        done
fi


# Check registrations.
if [ "$registrationssip" ]; then

        for p in $registrationssip
        do
                command_output=`sudo $ASTERISK -rx "sip show registry " 2>&1`

                registro=`echo "$command_output" | grep $p | awk '{print $5;}'`


                if [ "$registro" = "Registered" ]; then
                        test_reg=1
                else
                        test_reg=0
                fi

                xml_troncales=" $xml_troncales 
                <result>
                <channel>$p</channel>
		<unit>Registro</unit>
                <mode>Absolute</mode>
                <float>1</float>
                <limitMode>1</limitMode>
                <limitMinWarning>1</limitMinWarning>
                <limitMinError>1</limitMinError>
                <limitErrorMsg>Registro Troncal SIP</limitErrorMsg>             
                <value>$test_reg</value>
                </result>
                "

        done

        
fi

# Check registrations.
if [ "$registrationsiax" ]; then
        
        for p in $registrationsiax
        do
                command_output=`sudo $ASTERISK -rx "iax2 show registry $p" 2>&1`

                registro=`echo "$command_output" |grep $p | awk '{print $5;}'`


                if [ "$registro" = "Registered" ]; then
                        test_reg=1
                else
                        test_reg=0
                fi

                xml_troncales=" $xml_troncales 
                <result>
                <channel>$p</channel>
		<unit>Registro</unit>
                <mode>Absolute</mode>
                <float>1</float>
                <limitMode>1</limitMode>
                <limitMinWarning>1</limitMinWarning>
                <limitMinError>1</limitMinError>
                <limitErrorMsg>Registro Troncal SIP</limitErrorMsg>  
                <value>$test_reg</value>
                </result>
                "

        done


fi


# llamadas simultaneas
llamadas=`sudo $ASTERISK -rx "core show calls" | grep active\ call | cut -d" " -f1`

# Discos 
raiz=`df -h / | awk '{print $5 " " $6}' | tail -n 1 |grep % |cut -d "%" -f 1` 
var=`df -h /var | awk '{print $5 " " $6}' | tail -n 1 |grep % |cut -d "%" -f 1`

# Consumo de RED
eth0_R1=`cat /sys/class/net/eth0/statistics/rx_bytes`
eth0_T1=`cat /sys/class/net/eth0/statistics/tx_bytes`
eth1_R1=`cat /sys/class/net/eth1/statistics/rx_bytes`
eth1_T1=`cat /sys/class/net/eth1/statistics/tx_bytes`

sleep 1
eth0_R2=`cat /sys/class/net/eth0/statistics/rx_bytes`
eth0_T2=`cat /sys/class/net/eth0/statistics/tx_bytes`

eth1_R2=`cat /sys/class/net/eth1/statistics/rx_bytes`
eth1_T2=`cat /sys/class/net/eth1/statistics/tx_bytes`

eth0_TBPS=`expr $eth0_T2 - $eth0_T1`
eth0_RBPS=`expr $eth0_R2 - $eth0_R1`
eth0_TbitPS=`expr $eth0_TBPS `
eth0_RbitPS=`expr $eth0_RBPS `

eth1_TBPS=`expr $eth1_T2 - $eth1_T1`
eth1_RBPS=`expr $eth1_R2 - $eth1_R1`

eth1_TbitPS=`expr $eth1_TBPS \* 8`
eth1_RbitPS=`expr $eth1_RBPS \* 8`

# Media CPU

cpu=`cat /proc/loadavg |awk '{print $1}'`

#SWAP 

swap_total=`free  | grep Swap | awk '{print $2;}'`
swap_ocupada=`free  | grep Swap | awk '{print $3;}'`

swap=`expr $swap_ocupada \* 100 / $swap_total`

#Memoria RAM

ram_total=`free  | grep Mem | awk '{print $2;}' `
ram_activa=`free  | grep Mem | awk '{REST = $3 - $5 - $6 - $7 } END {print REST;}'`

ram=`expr $ram_activa \* 100  / $ram_total`


echo '
<prtg>
   <result>
       <channel>Llamadas simultaneas</channel>
       <value>'$llamadas'</value>
   </result>
   '$xml_troncales'
   <result>
        <channel>Disco Raiz /</channel>
        <unit>Percent</unit>
        <mode>Absolute</mode>
        <float>1</float>
        <limitMode>1</limitMode>
        <limitMaxWarning>75</limitMaxWarning>
        <limitMaxError>85</limitMaxError>
        <limitErrorMsg>Disco Raiz</limitErrorMsg> 
       <value>'$raiz'</value>
   </result>
   <result>
        <channel>Disco VAR /var</channel>
        <unit>Percent</unit>
        <mode>Absolute</mode>
        <float>1</float>
        <limitMode>1</limitMode>
        <limitMaxWarning>75</limitMaxWarning>
        <limitMaxError>85</limitMaxError>
        <limitErrorMsg>Disco var</limitErrorMsg>
        <value>'$var'</value>
   </result>
   <result>
        <channel>Memoria RAM</channel>
        <unit>Percent</unit>
        <mode>Absolute</mode>
        <float>1</float>
        <limitMode>1</limitMode>
        <limitMaxWarning>80</limitMaxWarning>
        <limitMaxError>90</limitMaxError>
        <limitErrorMsg>RAM</limitErrorMsg>
        <value>'$ram'</value>
   </result>
   <result>
        <channel>Memoria SWAP</channel>
        <unit>Percent</unit>
        <mode>Absolute</mode>
        <float>1</float>
        <limitMode>1</limitMode>
        <limitMaxWarning>20</limitMaxWarning>
        <limitMaxError>30</limitMaxError>
        <limitErrorMsg>Swap</limitErrorMsg>
        <value>'$swap'</value>
   </result>

   <result>
        <channel>CPU Media</channel>
        <unit>Percent</unit>
        <mode>Absolute</mode>
        <float>1</float>
        <limitMode>1</limitMode>
        <limitMaxWarning>50</limitMaxWarning>
        <limitMaxError>80</limitMaxError>
        <limitErrorMsg>Disco Raiz</limitErrorMsg>
        <value>'$cpu'</value>
   </result>


   <result>
       <channel>TX Eth0</channel>
       <unit>SpeedNet</unit>
       <volumeSize>KiloBit</volumeSize>
       <mode>Absolute</mode>
       <showChart>1</showChart>
       <showTable>1</showTable>
       <warning>0</warning>
       <float>0</float>
       <value>'$eth0_TbitPS'</value>
   </result>
   <result>
       <channel>RX Eth0</channel>
       <unit>SpeedNet</unit>
       <volumeSize>KiloBit</volumeSize>
       <mode>Absolute</mode>
       <showChart>1</showChart>
       <showTable>1</showTable>
       <warning>0</warning>
       <float>0</float>
       <value>'$eth0_RbitPS'</value>
   </result>
   <result>
       <channel>TX Eth1</channel>
       <unit>SpeedNet</unit>
       <volumeSize>KiloBit</volumeSize>
       <mode>Absolute</mode>
       <showChart>1</showChart>
       <showTable>1</showTable>
       <warning>0</warning>
       <float>0</float>
       <value>'$eth1_TbitPS'</value>
   </result>
   <result>
       <channel>RX Eth1</channel>
       <unit>SpeedNet</unit>
       <volumeSize>KiloBit</volumeSize>
       <mode>Absolute</mode>
       <showChart>1</showChart>
       <showTable>1</showTable>
       <warning>0</warning>
       <float>0</float>
       <value>'$eth1_RbitPS'</value>
   </result>
   <text>Estado vUCS: '$descripcion'</text>
</prtg>
'

# Ejemplo custom
#   <result>
#       <channel>Demo Custom</channel>
#       <unit>Custom</unit>
#       <customUnit>Pieces</customUnit>
#       <mode>Absolute</mode>
#       <showChart>1</showChart>
#       <showTable>1</showTable>
#       <warning>0</warning>
#       <float>0</float>
#       <value>855</value>
#   </result>

