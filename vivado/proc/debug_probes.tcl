##############################################################################
## This file is part of 'SLAC Firmware Standard Library'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'SLAC Firmware Standard Library', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

## Create a Debug Core Function
proc CreateDebugCore {ilaName} {

   # Delete the Core if it already exist
   delete_debug_core -quiet [get_debug_cores ${ilaName}]

   # Create the debug core
   if { [VersionCompare 2017.2] <= 0 } {
      create_debug_core ${ilaName} labtools_ila_v3
   } else {
      create_debug_core ${ilaName} ila
   }
   set_property C_DATA_DEPTH 1024       [get_debug_cores ${ilaName}]
   set_property C_INPUT_PIPE_STAGES 2   [get_debug_cores ${ilaName}]

   # Force a reset of the implementation
   reset_run impl_1
}

## Sets the clock on the debug core
proc SetDebugCoreClk {ilaName clkNetName} {
   set_property port_width 1 [get_debug_ports  ${ilaName}/clk]
   connect_debug_port ${ilaName}/clk [get_nets ${clkNetName}]
}

## Get Current Debug Probe Function
proc GetCurrentProbe {ilaName} {
   return ${ilaName}/probe[expr [llength [get_debug_ports ${ilaName}/probe*]] - 1]
}

## Probe Configuring function
proc ConfigProbe {ilaName netName} {

   # determine the probe index
   set probeIndex ${ilaName}/probe[expr [llength [get_debug_ports ${ilaName}/probe*]] - 1]

   # get the list of netnames
   set probeNet [lsort -increasing -dictionary [get_nets ${netName}]]

   # calculate the probe width
   set probeWidth [llength ${probeNet}]

   # set the width of the probe
   set_property port_width ${probeWidth} [get_debug_ports ${probeIndex}]

   # connect the probe to the ila module
   connect_debug_port ${probeIndex} ${probeNet}

   # increment the probe index
   create_debug_port ${ilaName} probe
}

## Write the port map file
proc WriteDebugProbes {ilaName {filePath ""}} {

   # Delete the last unused port
   delete_debug_port [get_debug_ports [GetCurrentProbe ${ilaName}]]

   # Check if write_debug_probes is support
   if { [VersionCompare 2017.2] <= 0 } {
      # Write the port map file
      write_debug_probes -force ${filePath}
   } else {
      # Check if not empty string
      if { ${filePath} != "" } {
         puts "\n\n\n\n\n********************************************************"
         puts "WriteDebugProbes(): Vivado's 'write_debug_probes' procedure has been deprecated in 2017.3"
         puts "Instead the debug_probe file will automatically get copied in the ruckus/system_vivado.mk COPY_PROBES_FILE() function"
         puts "********************************************************\n\n\n\n\n"
      }
   }
}

## Copy .LTX file to output image directory
proc CopyLtxFile { } {
   # Get variables
   source -quiet $::env(RUCKUS_DIR)/vivado/env_var.tcl
   source -quiet $::env(RUCKUS_DIR)/vivado/messages.tcl
   set imagePath "${IMAGES_DIR}/$::env(IMAGENAME)"
   # Copy the .ltx file (if it exists)
   if { [file exists ${OUT_DIR}/debugProbes.ltx] == 1 } {
      exec cp -f ${OUT_DIR}/debugProbes.ltx ${imagePath}.ltx
      puts "Debug Probes file copied to ${imagePath}.ltx"
   } elseif { [file exists ${IMPL_DIR}/debug_nets.ltx] == 1 } {
      exec cp -f ${IMPL_DIR}/debug_nets.ltx ${imagePath}.ltx
      puts "Debug Probes file copied to ${imagePath}.ltx"
   } else {
      puts "No Debug Probes found"
   }
}
