#! /bin/sh
# Coded by Kfuji
#J.A.M.S.W.
#Just Another Minecraft Server Wrapper Attempt

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

find_mcproc_func()
{
processis=$(ps aux | grep -i "$mcdir/$mcjar" | grep -v "grep")
check_proc_success=$?
pidis=$(echo "$processis" | awk '{print $2}')
jaris=$(echo "processis" | grep -o "$mcdir/$mcjar")
wait

}

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
	
#Check to see if minecraft is already running, if it is, do not start another one.

find_mcproc_func

if [[ "$check_proc_success" != "0" && ! "$jaris" ]];then
echo "No Minecraft server found running."
mc_was_running=no
else
echo "Jar found pid is $pidis"
mc_was_running=yes
fi

#Start Minecraft in our screen session.
# "stuff" below is a screen command to 'buffer' our 'startmccmd' as a string, and then emulate pressing the enter key with "`echo -ne '\015'`"

if [ "$mc_was_running" == "no" ];then

        echo "Server checks complete. $mc_server_name was not found to be running. Starting now...."

        screen -S mc_screen_proc -X stuff "java $mc_min_ram $mc_max_ram -jar $mcdir/$mcjar nogui"`echo -ne '\015'`

        ps -aux | grep "$mcdir/$mcjar" | grep -v grep | awk '{print $2}' &> $mcdir/mc.pid
		
else

		echo "Minecraft is already running please check before trying again."
		
fi

wait
}

stop_minecraft_func()
{
#Do a dip to get current status for vars
find_mcproc_func

if [[ ! "$mcdir/mc.pid" ]];then
pid_file=$(cat $mcdir/mc.pid)
pid_file_success=$?
else
pid_file_success="1"
fi

	if kill "$pid_file" ; then
		echo "Process found, kill signal sent."
		#TODO
		#CODE ALTERNITAVE SERVER KILL SUCH AS SENDING A STRING TO MCCONSOLE BY SCREEN BUFFER WITH ENTER PRESS EMULATION
		#TODO
	else
	
	echo "Errors Detected. See above."
		
		if [ "$pid_file_success" == 0 ];then
	
			echo "Last known PID was: $pid_file"
			echo "Would you like to try again? kill PID?: $pid_file"
			
			select killmenu1 in "Yes" "No"
            do
                case $killmenu1 in
                     "Yes" ) kill "$pid_file" ; break;;
                     "No" ) break;;
                esac
            done
		
		else

			echo "$mcdir/mc.pid does not appear to have the last process ID.\n"
			echo "See below for current running server process if found."
			
			find_mcproc_func
			
			echo "$processis"
			
			echo "Would you like us to kill PID?: $pidis"
			
			select killmenu2 in "Yes" "No"
            do
                case $killmenu2 in
                     "Yes" ) kill "$pidis" ; break;;
                     "No" ) break;;
                esac
            done

		fi
	fi
}

reboot_minecraft_func()
{
find_mcproc_func

        if [ "$check_proc_success" != "0" ]
                then
                        echo "Server is not running would you like to start it?"
                        select reboot_menu_var in "Yes" "No"
                        do
                                case $reboot_menu_var in
                                        "Yes" ) start_minecraft_func && break;;
                                        "No" ) break;;
                                esac
                        done
                else

                echo "Server is online. Starting reboot..."

                        while [ "check_proc_success" = "0" ]
                        do
                                if [ "check_proc_success" = "0" ]
                                then
                                        echo "Server is still shutting down waiting 5 seconds before checking again."
                                        sleep 5
                                        find_mcproc_func
                                else
                                        break
                                fi
                        done

                echo "Server is offline starting now..."
				start_minecraft_func
        fi
}

check_minecraft_func()
{
find_mcproc_func

if [ "$$check_proc_success" = 0 ];then

        local server_is_up_var=up
		echo "$mc_server_name is running"	
		echo "Its Process ID is: $last_pid"
else
        local server_is_up_var=down
fi

echo "$mc_server_name is: $server_is_up_var"
}

attach_mc_screen_func()
{
screen -r mc_screen_proc
screen -S mc_screen_proc -X stuff 'echo "You have Attached to the server, to detach press CTRL+A then let go and tap D"'$(echo -ne '\015')
}

#-----------------FUNC-----------------

#-----------------MAIN-----------------

COLUMNS=20
export PS3="Please use numbers to navigate:"

	if [ -f "$mcdir/$banner_file" ]
	then
		echo ""
		cat "$mcdir/$banner_file"
		echo ""
	fi

echo "Welcome to "$mc_server_name" Minecraft Server Menu."

select menu_var in "Start Server" "Stop Server" "View Server" "Check Server" "Reboot Server" "Exit"

do
        case $menu_var in
                 "Start Server")
                        start_minecraft_func ; break;;
                "Stop Server")
                        stop_minecraft_func ; break;;
                "View Server")
                        attach_mc_screen_func ; break;;
                "Check Server")
                        check_minecraft_func ; break;;
                "Reboot Server")
                        reboot_minecraft_func ; break;;
                "Exit") 
						break;;
        esac
done

#DEBUG
echo "Script Complete"
exit 0


#-----------------MAIN-----------------