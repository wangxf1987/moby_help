#!/usr/bin/sh
# docker file, array
dockers=(docker 
         docker-containerd
         docker-containerd-ctr 
         docker-containerd-shim
         docker-init
         docker-proxy 
         docker-runc
         dockerd)
# target hosts, array
host_list=(172.19.147.9
           172.19.147.10 
           172.19.147.11 
           172.19.147.12 
           172.19.147.13)
# get the contaier id for moby env, and if get a lot of
# containers, the script will be exit.
con_id_count=$(docker ps -q|wc -l)
# where are the compiled files ?
files_src="/home"

echo -e "###Copy file from Container###\n"
if [ "$con_id_count" -eq "1" ];then
    con_id=$(docker ps -q)
    echo -e "\nCopy files from Container $con_id,and the number of files is ${#dockers[*]}\n"
    for item in ${dockers[@]};
    do  
        echo -e "\nCopy -> $item"
        docker cp $con_id:/usr/local/bin/$item $files_src
        echo -e "$item Copied.\n"
    done
    echo "All copies have been completed. Please check files under the $files_src"
else
    echo "Error: Found a lot of containers."
    exit 1
fi

echo -e "###Clear logs###\n"
for host in ${host_list[@]};
do
    # clear all logs
    echo -e "Clear all logs on the $host.\n"
    ssh root@$host 'echo "" > /var/log/messages'
    if [ $? -ne 0 ];then
        echo -e "Error: ssh and executed commands failtrue.\n"
    fi    
done

echo -e "###Copy file to target host###\n"
for host in ${host_list[@]};
do  
    # stop docker service
    echo -e "Stop docker service on the $host.\n"
    ssh root@$host 'systemctl stop docker'
    if [ $? -ne 0 ];then
        echo -e "Error: ssh and executed commands failtrue.\n"
    fi
    
    # copy files to target host
    for file_item in ${dockers[@]};
    do
        echo -e "Copy $file_item to the $host ...\n"
        scp $files_src/$file_item root@$host:/usr/bin/$file_item
        if [ $? -ne 0 ]; then
            echo -e "Error: Copy failed\n"
            exit 1
        else
            echo -e "Done\n"
        fi
    done

    # start docker service
    echo -e "Start docker service on the $host.\n"
    ssh root@$host 'systemctl start docker'
    if [ $? -ne 0 ];then
        echo -e "Error: ssh and executed commands failtrue.\n"
    fi
done

# clear files on the locahost
echo -e "Clear files on the localhost"
for del_item in ${dockers[@]};
do
    rm -rf $files_src/$del_item
done
