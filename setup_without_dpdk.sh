set -e

## install ovs-dpdk
export HOME=$HOME
cd $DPDK_DIR


cd $HOME
export OVS_DIR=$HOME/OpenvSwitch-pof/
cd $OVS_DIR
#./boot.sh                           ## run once when first run

## configure, can use '-march=native' accelerate ovs-pof packet processing
#./configure --with-dpdk=$DPDK_BUILD
# ./configure CFLAGS="-g -O0" --with-dpdk=$DPDK_BUILD  ## way1: use 'dpdk', with lower performance
./configure CFLAGS="-g -O2 -march=native" 

## compilation and install
make -j24
make install




mkdir -p /usr/local/etc/openvswitch
mkdir -p /usr/local/var/run/openvswitch
#rm /usr/local/etc/openvswitch/conf.db
ovsdb-tool create /usr/local/etc/openvswitch/conf.db  \
            /usr/local/share/openvswitch/vswitch.ovsschema
ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
         --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
         --pidfile --detach
#     ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
#         --remote=db:Open_vSwitch,Open_vSwitch,manager_options \
#         --private-key=db:Open_vSwitch,SSL,private_key \
#         --certificate=Open_vSwitch,SSL,certificate \
#         --bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert --pidfile --detach
ovs-vsctl --no-wait init
export DB_SOCK=/usr/local/var/run/openvswitch/db.sock


sleep 1s
ovs-vswitchd unix:$DB_SOCK --pidfile --detach
#     ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024,0"  ## for multiple threads across cores.
#     ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024,1024"
#     ovs-vswitchd unix:$DB_SOCK --pidfile --detach
#     ovs-vsctl set Open_vSwitch . other_config:pmd-cpu-mask=6
ovs-appctl vlog/set ANY:ANY:INFO
ovs-appctl vlog/set ofproto:ANY:dbg
ovs-vsctl add-br br0 -- set bridge br0 datapath_type=netdev



## set datapath-id of ovs, must be 8B decimal number, cannot omit zeros.
ovs-vsctl set bridge br0 other-config:datapath-id=0000000000000002


