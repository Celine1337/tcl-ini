#!/usr/bin/env tclsh
# tcl-ini - lint and query INI files. Pure Tcl, no dependencies.
package require Tcl 8.6

proc usage {} {
    puts stderr {usage:
  tcl-ini validate <file.ini>          report structural problems (exit 1 on error)
  tcl-ini get <file.ini> <section> <key>   print a value (exit 1 if missing)
  tcl-ini sections <file.ini>          list section names in order
  tcl-ini keys <file.ini> <section>    list keys of a section}
    exit 2
}

# Parse an INI file into a dict: section -> dict(key -> value).
# Returns {data errors warnings} where errors/warnings are lists of
# {line message}. Parsing rules:
#   [section]          section header
#   key = value        assignment ('=' or ':' separator)
#   # or ; full line   comment
# Keys before any section, duplicate sections/keys and malformed lines are flagged.
proc parse_ini {path} {
    set fh [open $path r]
    set data [dict create]
    set errors {}
    set warnings {}
    set section ""
    set seenSections [dict create]
    set lineno 0
    while {[gets $fh line] >= 0} {
        incr lineno
        set t [string trim $line]
        if {$t eq ""} { continue }
        set c [string index $t 0]
        if {$c eq "#" || $c eq ";"} { continue }
        if {$c eq "\["} {
            if {[string index $t end] ne "\]"} {
                lappend errors [list $lineno "unterminated section header: $t"]
                continue
            }
            set name [string trim [string range $t 1 end-1]]
            if {$name eq ""} {
                lappend errors [list $lineno "empty section name"]
                continue
            }
            if {[dict exists $seenSections $name]} {
                lappend warnings [list $lineno "duplicate section \[$name\] (later values merge)"]
            } else {
                dict set seenSections $name 1
                dict set data $name [dict create]
            }
            set section $name
            continue
        }
        # assignment: find first '=' or ':'
        set eq [string first "=" $t]
        set co [string first ":" $t]
        if {$eq < 0} { set sep $co } elseif {$co < 0} { set sep $eq } else {
            set sep [expr {min($eq, $co)}]
        }
        if {$sep <= 0} {
            lappend errors [list $lineno "malformed line (expected key = value): $t"]
            continue
        }
        set key [string trim [string range $t 0 $sep-1]]
        set val [string trim [string range $t $sep+1 end]]
        if {$key eq ""} {
            lappend errors [list $lineno "empty key"]
            continue
        }
        if {$section eq ""} {
            lappend errors [list $lineno "key \"$key\" appears before any section"]
            continue
        }
        if {[dict exists $data $section $key]} {
            lappend errors [list $lineno "duplicate key \"$key\" in section \[$section\]"]
        }
        dict set data $section $key $val
    }
    close $fh
    return [list $data $errors $warnings]
}

proc read_file {path} {
    if {![file exists $path]} {
        puts stderr "tcl-ini: no such file: $path"
        exit 2
    }
    return [parse_ini $path]
}

proc cmd_validate {path} {
    lassign [read_file $path] data errors warnings
    foreach e $errors {
        lassign $e ln msg
        puts "ERROR line $ln: $msg"
    }
    foreach w $warnings {
        lassign $w ln msg
        puts "WARN  line $ln: $msg"
    }
    set ne [llength $errors]
    set nw [llength $warnings]
    puts "$ne error(s), $nw warning(s)"
    exit [expr {$ne > 0 ? 1 : 0}]
}

proc cmd_get {path section key} {
    lassign [read_file $path] data errors warnings
    if {[dict exists $data $section $key]} {
        puts [dict get $data $section $key]
        exit 0
    }
    puts stderr "tcl-ini: no key \"$key\" in section \[$section\]"
    exit 1
}

proc cmd_sections {path} {
    lassign [read_file $path] data errors warnings
    foreach s [dict keys $data] { puts $s }
    exit 0
}

proc cmd_keys {path section} {
    lassign [read_file $path] data errors warnings
    if {![dict exists $data $section]} {
        puts stderr "tcl-ini: no section \[$section\]"
        exit 1
    }
    foreach k [dict keys [dict get $data $section]] { puts $k }
    exit 0
}

set argv0name "tcl-ini"
if {$argc < 1} { usage }
set cmd [lindex $argv 0]
switch -- $cmd {
    validate {
        if {$argc != 2} { usage }
        cmd_validate [lindex $argv 1]
    }
    get {
        if {$argc != 4} { usage }
        cmd_get [lindex $argv 1] [lindex $argv 2] [lindex $argv 3]
    }
    sections {
        if {$argc != 2} { usage }
        cmd_sections [lindex $argv 1]
    }
    keys {
        if {$argc != 3} { usage }
        cmd_keys [lindex $argv 1] [lindex $argv 2]
    }
    default { usage }
}