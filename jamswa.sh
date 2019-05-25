#! /bin/sh
# Coded by Kfuji
#J.A.M.S.W.A
#Just Another Minecraft Server Wrapper Attempt
#Your file structure should look something like this:
#
# Minecraft/
# ├── eula.txt
# ├── JAMSWA
# │   ├── banner.txt
# │   ├── jamswa.settings
# │   ├── jamswa.sh
# │   ├── LICENSE
# │   └── README.md
# ├── logs
# ├── minecraft_server.1.14.1.jar
# ├── server.properties
# └── world
#

#-----------------FUNC-----------------

#The primary function that locates the server process and sets up the variables for the script.
find_mcproc_func()
{
processis=$(ps aux | grep -i "$mcdir/$mcjar" | grep -v "grep")
check_proc_success=$?
pidis=$(echo "$processis" | awk '{print $2}')
wait
}

#A small loop funciton to check the minecraft server, and if its still up, wait 5 seconds and check again, repeat until down.
shuttingdown_check_loop()
{
        while true;
        do
            if [ "$check_proc_success" = "0" ]
            then
                 echo "Server is still shutting down waiting 5 seconds before checking again."
                                        sleep 5
                                        find_mcproc_func
                                else
                                        break
                                fi
        done
}

start_minecraft_func()
{
#Check to see if we are already running our screen session.

screen -list | grep -i mc_screen_proc &> /dev/null
is_screen_up=$?

#If our screen session is not up then start it up.

	if [ "$is_screen_up" != 0 ]
	then
		screen -Sdm mc_screen_proc
		echo "Starting fresh screen session."
	else
		echo "Previous screen session found."
	fi
	
#Check to see if minecraft is already running, if it is, do not start another one.

find_mcproc_func
jaris=$(echo "$processis" | grep -o "$mcdir/$mcjar")

	if [[ "$check_proc_success" != "0" && ! "$jaris" ]]
	then
		echo "No Minecraft server found running."
		mc_was_running=no
	else
		echo "Jar found pid is $pidis"
		mc_was_running=yes
	fi

#Start Minecraft in our screen session.
# "stuff" below is a screen command to 'buffer' our 'startmccmd' as a string, and then emulate pressing the enter key with "`echo -ne '\015'`"

	if [ "$mc_was_running" == "no" ]
	then
			echo "Server checks complete." 
			echo "$mc_server_name was not found to be running."
			sleep .5
			echo "Starting $mcdir/$mcjar now..."			

			screen -S mc_screen_proc -X stuff "cd $mcdir"`echo -ne '\015'` #Ran into a bug caused by someone changing the working directory of our screeen session this ensures its always correct.
			screen -S mc_screen_proc -X stuff "java $mc_min_ram $mc_max_ram -jar $mcdir/$mcjar nogui"`echo -ne '\015'`
	
			ps -aux | grep "$mcdir/$mcjar" | grep -v grep | awk '{print $2}' > $mcdir/mc.pid
						
	else
			echo "Minecraft is already running please check before trying again."
	fi
	
wait

}

#Stop minecraft function, designed to figure out the system its on and find the process.
stop_minecraft_func()
{
#Do a dip to get current status for vars
find_mcproc_func

if [ -f "$mcdir/mc.pid" ]
then
pid_file=$(cat $mcdir/mc.pid)
else
pid_file_success="1"
fi

	if kill "$pid_file"
	then
		echo "Process found, kill signal sent."

		sleep 5
		
		shuttingdown_check_loop

        echo "Server has finished shutting down."		
		
	else
	
		echo "Errors Detected."
		
		if [ "$pid_file_success" == 0 ]
		then
	
			echo "Last known PID was: $pid_file"
			echo "Would you like to try again? kill PID?: $pid_file"
			
			select killmenu1 in "Yes" "No"
            do
                case $killmenu1 in
                     "Yes" ) kill "$pid_file" ; break;;
                     "No" ) break;;
					 *) echo "$failtext" >&2
                esac
            done
		
		else

			echo "$mcdir/mc.pid does not appear to have the last process ID."
			echo ""
			echo "See below for current running server process if found."
			
			find_mcproc_func
			
			echo "$processis"
			
			echo "Would you like us to kill PID?: $pidis"
			
			select killmenu2 in "Yes" "No"
            do
                case $killmenu2 in
                     "Yes" ) kill "$pidis" ; break;;
                     "No" ) break;;
					 *) echo "$failtext" >&2
                esac
            done

		fi
	fi
}

#Reboot cycle utility command. Checks server to ensure it wont launch two.
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
										*) echo "$failtext" >&2
                                esac
                        done
                else

                echo "Server is online. Starting reboot..."

				stop_minecraft_func
				
				sleep 5
				
				shuttingdown_check_loop

                echo "Server is offline starting now..."
				start_minecraft_func
        fi
}

#Basic server check function.
check_minecraft_func()
{
find_mcproc_func

if [ "$check_proc_success" == 0 ]
then

        local server_is_up_var=up
		echo "$mc_server_name is running"	
		echo "Its Process ID is: $pidis"
		jaris=$(echo "$processis" | grep -o "$mcdir/$mcjar")
		echo "Jarfile is at: $jaris"
else
        local server_is_up_var=down
fi

echo "$mc_server_name is: $server_is_up_var"
}

#Attach to screen session that we created for our MC server to live in.
attach_mc_screen_func()
{
screen -r mc_screen_proc
screen -S mc_screen_proc -X stuff 'echo "You have Attached to the server, to detach press CTRL+A then let go and tap D"'$(echo -ne '\015')
}

#Install Menu Function, shows the install menu.
install_menu_func()
{
echo ""
	select install_menu_var in "Install symlink to $HOME/bin" "Install symlink to /usr/bin [Will prompt for admin]" "Edit $script_root/jamswa.settings" "Exit";do
			case $install_menu_var in
					"Install symlink to $HOME/bin")							
							read -p "Enter the name of the 'cmd' you want to type to bring up YAMSWA: " -i jamswa -e users_choice
							mkdir -p $HOME/bin && ln -s $script_file $HOME/bin/$users_choice
							echo "Symlink created in $HOME/bin. You may now type "$users_choice" to run YAMSWA"
							break ;;
					"Install symlink to /usr/bin [Will prompt for admin]")
							read -p "Enter the name of the 'cmd' you want to type to bring up YAMSWA: " -i jamswa -e users_choice
							sudo ln -s $script_file /usr/bin/$users_choice
							echo "Symlink created in /usr/bin. You may now type "$users_choice" to run YAMSWA"
							break ;;
					"Edit $script_root/jamswa.settings")
							nano "$script_root/jamswa.settings"					
							wait
							break;;
					"Exit") 
							break;;
					*) echo "$failtext" >&2
			esac
	done
}

#Main Menu Function, shows the main menu.
main_menu()
{
local COLUMNS=20
echo ""
	select menu_var in "Start Server" "Stop Server" "View Server" "Check Server" "Reboot Server" "Install Menu" "Exit";do
			case $menu_var in
					"Start Server")
							start_minecraft_func ; break ;;
					"Stop Server")
							stop_minecraft_func ; break ;;
					"View Server")
							attach_mc_screen_func ; showmenu=0 ; break;;
					"Check Server")
							check_minecraft_func ; break ;;	# Would be replaced.
							#user_checked=1 ; break ;;		# New Code I want to try.
							#								# Addition Group #1
					"Reboot Server")
							reboot_minecraft_func ; break ;;
					"Install Menu")
							install_menu_func ; break ;;
					"Exit") 
							showmenu=0 ; break;;
					*) echo "$failtext" >&2
			esac
			
			#if [ "$user_checked" == "1" ];then		# New Code I want to try.
			#user_checked=0							# Addition Group #1
			#echo ""								# Goal: Get text output below the menu.
			#check_minecraft_func					# Will need to test to see if this is a good/bad idea because the user would be able to select another task while one is technically running. This may also be good if I can do error checking to tell them the task is already running.
			#fi										
			
	done
}

#-----------------FUNC-----------------

#-----------------MAIN-----------------

#Ensures user has correct requirements or else exit.
screen -v | grep -i screen &> /dev/null
has_screen1=$?
if [ -f /usr/bin/screen ]; then has_screen2=0 ;else has_screen2=1 ;fi
if [[ "$has_screen1" != "0" && "$has_screen1" != "0" ]];then echo "You do not have Screen installed. This is required."; exit 1 ; fi

#Script learns its own location and sets variables accordingly.
script_file=$(readlink -f "$0")
script_file_success=$?
script_root=$(dirname $script_file)
script_root_success=$?
if [[ "script_root_success" != "0" && "$script_file_success" != "0" ]];then echo "Something very bad has happened. Exiting"; exit 1 ; fi

#jamswa.settings file structure check
if [ -f "$script_root/jamswa.settings" ];then echo "jamswa.settings is missing. This is required."; exit 1 ; fi
source "$script_root"/jamswa.settings

if [ "$mcjar" == "NameMeYourMCDotJarFile.jar" ] ;then echo "You did not edit jamswa.settings You need to set a JAR file for mcjar"; exit 1 ;fi
if [ "$mcdir" == "Change/Me/To/Your/Directory" ];then echo "You did not edit jamswa.settings You need to set the directory/path for your minecraft/ folder."; exit 1 ;fi

#Server Branding
if [ -f "$mcdir/$banner_file" ];then echo "" ; cat "$mcdir/$banner_file" ; echo "" ; fi
echo "Welcome to "$mc_server_name" Minecraft Server Menu."

#Main Menu loop
showmenu=1
	while true
	do
		if [ "$showmenu" == "0" ]
		then
			break
		fi	
		main_menu
	done

#Wait and Exit
wait
exit 0

#-----------------MAIN-----------------
