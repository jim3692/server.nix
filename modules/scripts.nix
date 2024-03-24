{ pkgs, ... }:

let
  attach-new-interfaces-to-bridges = pkgs.writeShellScriptBin "attach" ''
    shopt -s expand_aliases

    WORKING_DIR=/tmp/bridge-watch
    mkdir -p $WORKING_DIR

    LAST_ID_FILE=$WORKING_DIR/last-id
    [ ! -f $LAST_ID_FILE ] && echo 1 >$LAST_ID_FILE

    alias get_last_id="cat $LAST_ID_FILE"
    set_last_id () {
      echo $1 >$LAST_ID_FILE
    }

    ${pkgs.iproute2}/bin/ip link | grep -oE '^[0-9]+:[^:]+' | sed 's/@.*//' |
      while read line; do
        id=`echo $line | ${pkgs.busybox}/bin/awk '{ print $1 }' | sed 's|:||'`
        interface=`echo $line | ${pkgs.busybox}/bin/awk '{ print $2 }'`
        [ $id -le `get_last_id` ] && continue

        target=`${pkgs.jq}/bin/jq -r ".[\"$interface\"]" "$CONFIG_FILE"`
        [ ! $? -eq 0 ] && exit 1
        [ "$target" == "null" ] && continue

        ${pkgs.bridge-utils}/bin/brctl addif "$target" "$interface"
        [ ! $? -eq 0 ] && exit 1

        set_last_id $id
      done
  '';

  watch-interfaces = pkgs.writeShellScriptBin "watch-interfaces" ''
    ${pkgs.busybox}/bin/watch -t -n $INTERVAL ${attach-new-interfaces-to-bridges}/bin/attach
  '';

in {
  environment.systemPackages = [ watch-interfaces ];
}
