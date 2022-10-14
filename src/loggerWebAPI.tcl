proc ListDataGroups {printAPI} {
    set api "https://ops.aps.anl.gov/cgi-bin/oagMonitorDataReview.cgi?ListDataGroups=1"
    if {$printAPI} {
        puts $api
        exit
    }
    exec wget -o /tmp/aopLogging.junk -O /tmp/aopLogging.html $api
    set fid [open /tmp/aopLogging.html r]
    set data [read $fid]
    close $fid
    file delete /tmp/aopLogging.junk /tmp/aopLogging.html

    set lines [split $data \n]
    set body 0
    foreach line $lines {
        if {$body} {
            puts [join $line \n]
            exit
        }
        if {[string range [lindex $line 0] 0 4] == "<Body"} {
            set body 1
        }
    }
    exit
}

proc ListReadbackNames {printAPI DataGroup} {
    set api "https://ops.aps.anl.gov/cgi-bin/oagMonitorDataReview.cgi?DataGroup=${DataGroup}&ListReadbackNames=1"
    if {$printAPI} {
        puts $api
        exit
    }
    exec wget -o /tmp/aopLogging.junk -O /tmp/aopLogging.html $api
    set fid [open /tmp/aopLogging.html r]
    set data [read $fid]
    close $fid
    file delete /tmp/aopLogging.junk /tmp/aopLogging.html

    set lines [split $data \n]
    set body 0
    foreach line $lines {
        if {[string range [lindex $line 0] 0 5] == "</Body"} {
            set body 0
            exit
        }
        if {$body} {
            puts [join $line \n]
        }
        if {[string range [lindex $line 0] 0 4] == "<Body"} {
            set body 1
        }
    }
    exit
}

proc Plot {printAPI DataGroup ReadbackNames StartDay StartMonth StartYear EndDay EndMonth EndYear} {
    set Plot "++++Plot++++"
    set StartHour 0
    set EndHour 24
    set Size mpng
    set Background onwhite
    set LabelSize 0.03
    set Sparsing 1

    set api "https://ops.aps.anl.gov/cgi-bin/oagMonitorDataReview.cgi?DataGroup=${DataGroup}&ListReadbackNames=1"
    exec wget -o /tmp/aopLogging.junk -O /tmp/aopLogging.html $api
    set fid [open /tmp/aopLogging.html r]
    set data [read $fid]
    close $fid
    file delete /tmp/aopLogging.junk /tmp/aopLogging.html

    set lines [split $data \n]
    set pvapi ""
    foreach ReadbackName $ReadbackNames {
        set body 0
        set index 0
        foreach line $lines {
            if {[string range [lindex $line 0] 0 5] == "</Body"} {
                set body 0
                puts "Error: PV ReadbackName not found"
                exit
            }
            if {$body} {
                if {$line == $ReadbackName} {
                    break
                }
                incr index
            }
            if {[string range [lindex $line 0] 0 4] == "<Body"} {
                set body 1
            }
        }
        append pvapi "&${DataGroup}_ControlReadbackName=${index}"
    }

    set api "https://ops.aps.anl.gov/cgi-bin/oagMonitorDataReview.cgi?DataGroup=${DataGroup}${pvapi}&Plot=${Plot}&StartYear=${StartYear}&StartMonth=${StartMonth}&StartDay=${StartDay}&StartHour=${StartHour}&EndYear=${EndYear}&EndMonth=${EndMonth}&EndDay=${EndDay}&EndHour=${EndHour}&Size=${Size}&Background=${Background}&LabelSize=${LabelSize}&Sparsing=${Sparsing}"
    if {$printAPI} {
        puts $api
        exit
    }
    exec wget -o /tmp/aopLogging.junk -O /tmp/aopLogging.html $api

    set fid [open /tmp/aopLogging.html r]
    set data [read $fid]
    close $fid
    file delete /tmp/aopLogging.junk /tmp/aopLogging.html

    set lines [split $data \n]
    foreach line $lines {
        if {[string range [lindex $line 1] 0 3] == "src="} {
            set link [string range [lindex $line 1] 4 end-1]
            exec wget -o /tmp/aopLogging.junk -O /tmp/aopLogging.png $link
            exec eog /tmp/aopLogging.png &
            file delete /tmp/aopLogging.junk /tmp/aopLogging.html
            after 2000
            file delete /tmp/aopLogging.png
            exit
        }
    }
}

proc ExportCSV {printAPI DataGroup ReadbackNames StartDay StartMonth StartYear EndDay EndMonth EndYear OutputFile} {
    set Plot "++++Plot++++"
    set ExportCSV "Export+Data+(CSV)"
    set StartHour 0
    set EndHour 24
    set Size mpng
    set Background onwhite
    set LabelSize 0.03
    set Sparsing 1

    set api "https://ops.aps.anl.gov/cgi-bin/oagMonitorDataReview.cgi?DataGroup=${DataGroup}&ListReadbackNames=1"
    exec wget -o /tmp/aopLogging.junk -O /tmp/aopLogging.html $api
    set fid [open /tmp/aopLogging.html r]
    set data [read $fid]
    close $fid
    file delete /tmp/aopLogging.junk /tmp/aopLogging.html

    set lines [split $data \n]
    set pvapi ""
    foreach ReadbackName $ReadbackNames {
        set body 0
        set index 0
        foreach line $lines {
            if {[string range [lindex $line 0] 0 5] == "</Body"} {
                set body 0
                puts "Error: PV ReadbackName not found"
                exit
            }
            if {$body} {
                if {$line == $ReadbackName} {
                    break
                }
                incr index
            }
            if {[string range [lindex $line 0] 0 4] == "<Body"} {
                set body 1
            }
        }
        append pvapi "&${DataGroup}_ControlReadbackName=${index}"
    }

    set api "https://ops.aps.anl.gov/cgi-bin/oagMonitorDataReview.cgi?DataGroup=${DataGroup}${pvapi}&ExportCSV=${ExportCSV}&StartYear=${StartYear}&StartMonth=${StartMonth}&StartDay=${StartDay}&StartHour=${StartHour}&EndYear=${EndYear}&EndMonth=${EndMonth}&EndDay=${EndDay}&EndHour=${EndHour}&Size=${Size}&Background=${Background}&LabelSize=${LabelSize}&Sparsing=${Sparsing}"
    if {$printAPI} {
        puts $api
        exit
    }
    exec wget -o /tmp/aopLogging.junk -O $OutputFile $api

    puts Done
}

proc Usage {} {
    puts "Usage: tclsh loggerWebAPI.tcl \[-printAPI\] listDataGroups"
    puts "Usage: tclsh loggerWebAPI.tcl \[-printAPI\] listReadbackNames <DataGroup>"
    puts "Usage: tclsh loggerWebAPI.tcl \[-printAPI\] plot <StartDay> <EndDay> <DataGroup> <ReadbackName> \[<ReadbackName> ...\]"
    puts "Usage: tclsh loggerWebAPI.tcl \[-printAPI\] exportCSV <OutputFile> <StartDay> <EndDay> <DataGroup> <ReadbackName> \[<ReadbackName> ...\]"
    puts ""
    puts "Usage: tclsh loggerWebAPI.tcl \[-printAPI\] plot 9/16/2022 9/17/2022 linacVacuum L1:PC1:GUN"
    puts "Usage: tclsh loggerWebAPI.tcl \[-printAPI\] exportCSV data.csv 9/16/2022 9/17/2022 linacVacuum L1:PC1:GUN"
    exit
}

set printAPI 0
set mode ""
set i 0
if {[lindex $argv 0] == "-printAPI"} {
    set printAPI 1
    set i 1
}
if {[lindex $argv $i] == "plot"} {
    set mode [lindex $argv $i]
    incr i
    set StartDay [lindex $argv $i]
    incr i
    set EndDay [lindex $argv $i]
    incr i
    set DataGroup [lindex $argv $i]
    incr i
    set name [lindex $argv $i]
    while {[llength $name]} {
        lappend ReadbackNames $name
        incr i
        set name [lindex $argv $i]
    }
} elseif {[lindex $argv $i] == "exportCSV"} {
    set mode [lindex $argv $i]
    incr i
    set OutputFile [lindex $argv $i]
    incr i
    set StartDay [lindex $argv $i]
    incr i
    set EndDay [lindex $argv $i]
    incr i
    set DataGroup [lindex $argv $i]
    incr i
    set name [lindex $argv $i]
    while {[llength $name]} {
        lappend ReadbackNames $name
        incr i
        set name [lindex $argv $i]
    }
} elseif {[lindex $argv $i] == "listDataGroups"} {
    set mode [lindex $argv $i]
} elseif {[lindex $argv $i] == "listReadbackNames"} {
    set mode [lindex $argv $i]
    incr i
    set DataGroup [lindex $argv $i]
} else {
    Usage
}

if {$mode == "listDataGroups"} {
    ListDataGroups $printAPI
} elseif {$mode == "listReadbackNames"} {
    ListReadbackNames $printAPI $DataGroup
} elseif {$mode == "plot"} {
    set date [split $StartDay "/"]
    set StartMonth [lindex $date 0]
    set StartDay [lindex $date 1]
    set StartYear [lindex $date 2]
    
    set date [split $EndDay "/"]
    set EndMonth [lindex $date 0]
    set EndDay [lindex $date 1]
    set EndYear [lindex $date 2]

    Plot $printAPI $DataGroup $ReadbackNames $StartDay $StartMonth $StartYear $EndDay $EndMonth $EndYear
} elseif {$mode == "exportCSV"} {
    set date [split $StartDay "/"]
    set StartMonth [lindex $date 0]
    set StartDay [lindex $date 1]
    set StartYear [lindex $date 2]
    
    set date [split $EndDay "/"]
    set EndMonth [lindex $date 0]
    set EndDay [lindex $date 1]
    set EndYear [lindex $date 2]

    ExportCSV $printAPI $DataGroup $ReadbackNames $StartDay $StartMonth $StartYear $EndDay $EndMonth $EndYear $OutputFile
}
