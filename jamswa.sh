#! /bin/sh
# Coded by Kfuji

#-----------------TIPS AND CHANGEABLE SETTINGS-----------------
#YOU MUST CHANGE THIS VARIABLE TO BE YOUR MINECRAFT JAR FILE NAME
export mcjar="minecraft_server.1.14.1.jar"

#YOU MUST CHANGE THIS VARIABLE TO BE YOUR MINECRAFT ROOT DIRECTORY! (No Slash at the end)
export mcdir=/home/kfuji/Minecraft

#You can change theese variable if you need to edit Minecraft RAM Ammounts:
export mc_min_ram="-Xms2048M"
export mc_max_ram="-Xmx4096M"

#You will probablly want to brand your server, change the bellow to your server brand/name:
export mc_server_name="Minecraft 1.14.1 Server"

#You can put a banner file (ascii art, MOTD, etc) at /path/to/your/minecraft/banner.txt to be displayed when the menu is opened.
#Or change the below variable to target a different file.
export banner_file="banner.txt"

#Other Files Used:
# /path/to/your/minecraft/banner.txt (Not Required)
#-----------------TIPS AND CHANGEABLE SETTINGS-----------------


#-----------------FUNC-----------------

start_minecraft_func()
{
#Check to see if we are already running our screen session.
screen -list | grep -i mc_screen_proc &> /dev/null
is_screen_up=$?


#If our screen session is not up then start it up.
if [ "$is_screen_up" != 0 ];then
screen -Sdm mc_screen_proc
echo "Starting fresh screen session."
else
echo "Previous screen session found."
fi

#Check to see if minecraft is already running, if it is, stop script execution.
jar_is=$(ps -aux | grep "$mcdir/$mcjar" | grep -v grep)
jarfound=$?

if [[ "$jarfound" != "0" && ! "$jar_is" ]]; then
echo "Minecraft Is Down"
mc_was_running=no
else
pid_is=$( echo $jar_is | awk '{print $2}' )
echo "jar found pid is $pid_is"
echo "Minecraft Already Running"
mc_was_running=yes
exit 1
fi

#Start Minecraft in our screen session.
# "stuff" below is a screen command to 'buffer' our 'startmccmd' as a string, and then emulate pressing the enter key with "`echo -ne '\015'`"

if [ "$mc_was_running" == "no" ]
then

        echo "It appears to be safe to start the server. Starting now...."

        screen -S mc_screen_proc -X stuff "java $mc_min_ram $mc_max_ram -jar $mcdir/$mcjar nogui"`echo -ne '\015'`

        echo "Waiting 15 seconds"

        sleep 15

        echo "Checking for PID and writing to $mcdir/mc.pid"

        ps -aux | grep "$mcdir/$mcjar" | grep -v grep | awk '{print $2}' &> $mcdir/mc.pid

        echo "Outputting contents of $mcdir/mc.pid :"
        echo
        cat $mcdir/mc.pid

        wait

fi
}

stop_minecraft_func()
{
mcpid=$(cat $mcdir/mc.pid)
if kill "$mcpid" ;then
echo "Process found, sending kill signal..."
else
echo "Some error has occurred. See above. Last known PID was: $mcpid"
echo "Checking running processes for $mcdir/$mcjar"
processis=$(ps ux | grep -i "$mcdir/$mcjar" | grep -v "grep")
processpidis=$( echo "$processis" | awk '{print $2}')

echo "$mcdir/mc.pid does not appear to have the process ID."
			local PS3="Please input numbers to navigate:"
			select reboot_menu_var in "Yes" "No"
                                do
                                case $reboot_menu_var in
                                        "Yes" ) $mcdir/start_minecraft.sh && break;;
                                        "No" ) break;;
                                esac
                        done




fi




}

reboot_minecraft_func()
{
check_minecraft_func &> /dev/null

        if [ "$server_is_up_var" = "down"]
                then

                        echo "Server is not running would you like to start it?"
			local PS3="Please input numbers to navigate:"
                        select reboot_menu_var in "Yes" "No"
                                do
                                case $reboot_menu_var in
                                        "Yes" ) $mcdir/start_minecraft.sh && break;;
                                        "No" ) break;;
                                esac
                        done

                else

                echo "Server is online. Starting reboot..."
##############INSERT CODE TO START REBOOT HERE##############
                check_minecraft_func

                        while [ "server_is_up_var" = "up" ]
                        do

                                if [ "server_is_up_var" = "up" ]
                                then
                                        echo "Server is still shutting down waiting 5 seconds before checking again."
                                        sleep 5
                                        check_minecraft_func

                                else
                                        break
                                fi
                        done

                echo "Server is offline starting now..."
##############INSERT CODE TO START Server HERE##############
        fi
}

check_minecraft_func()
{
local last_pid=$( ps ux | grep -i "$mcdir/$mcjar" | grep -v "grep" | awk '{print $2}')
local is_server_up=$?

if [ "$is_server_up" = 0 ]
then
        local server_is_up_var=up
else
        local server_is_up_var=down
fi

echo "Server status is: $server_is_up_var"

if [ "$server_is_up_var" = "up" ]
then
echo "Its Process ID is: $last_pid"
fi
}

attach_mc_screen_func()
{
screen -r mc_screen_proc
screen -S mc_screen_proc -X stuff 'echo "You have Attached to the server, to detach press CTRL+A then let go and tap D"'$(echo -ne '\015')
}

#-----------------FUNC-----------------

#-----------------MAIN-----------------

if [ -f "$mcdir/$banner_file" ]
then
echo ""
cat $mcdir/$banner_file
echo ""
fi

echo "Welcome to "$mc_server_name" Minecraft Server Menu."
COLUMNS=20
PS3="Please input numbers to navigate:"
select menu_var in "Start Server" "Stop Server" "View Server" "Check Server" "Reboot Server" "Exit"
do
        case $menu_var in
                 "Start Server")
                        check_minecraft_func ; break
                        ;;
                "Stop Server")
                        stop_minecraft_func ; break
                        ;;
                "View Server")
                        attach_mc_screen_func ; break
                        ;;
                "Check Server")
                        check_minecraft_func ; break
                        ;;
                "Reboot Server")
                        reboot_minecraft_func ; break
                        ;;
                "Exit")
                        break
                        ;;
        esac
done

exit 0


#-----------------MAIN-----------------