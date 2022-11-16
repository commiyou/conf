# vim: ft=zsh

alias oscp="ossutil64 cp --recursive -u"
alias osget="ossutil64 cp --recursive -u"
alias osls="ossutil64 ls"
alias rplay="rosbag play"
alias rplayt="rosbag play --topics /tracking/tracked_object_marker /prediction/predicted_objects /current_pva --"
alias rlaunch="source ./devel/setup.sh && roslaunch planning planning.launch;"
alias rvalid="docker restart ctrl_node; source ./devel/setup.sh && roslaunch planning planning.launch"
alias rinstall="cd \$(git rev-parse --show-toplevel) && rm -rf build && mkdir -p build && cd build && conan install -u .. && cd .. && catkin_make install . -j11 -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -DCMAKE_BUILD_TYPE=Debug"
alias rupdate="cd \$(git rev-parse --show-toplevel) && catkin_make install . -j3 -DCMAKE_EXPORT_COMPILE_COMMANDS=1"


osdown ()
{
  yes N | ossutil64 cp --recursive -u $* . 
  while ls * | grep  temp$
  do
    yes N | ossutil64 cp --recursive -u $* .
    sleep 3
  done
}
