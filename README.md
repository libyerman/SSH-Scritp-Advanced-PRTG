# check_asterisk_system.sh
Script que muestra estado de la máquina asterisk y devuelve un XML válido para PRTG SSH script advanced."

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
