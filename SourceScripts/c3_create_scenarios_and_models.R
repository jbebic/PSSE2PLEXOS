#create other models/scenarios

#uses:
# load.file.path
# import.horizon.mayJune.file
# import.model.baseAgTx.file
# import.model.mayJune.file
# import.model.mayJuneAgTx.file
# enforced.interstate.lines.file
# isolated.nodes.to.remove.file
# compact.generic.import.files
# constraint.import.files

#make components of scenarios

#------------------------------------------------------------------------------|
# [[Tx configuration]] Aggregate transmission scenario ----
# -----------------------------------------------------------------------------|

#turn on "Aggregate Transmission" property for each region and assign a 
#reference node to each region

  #scenario to objects
scenario.agTx.to.objects <- initialize_table(Objects.sheet, 1, list(
  class = "Scenario", name = "Aggregate transmission in all regions", 
  category = "Transmission configuration"))
Objects.sheet <- merge_sheet_w_table(Objects.sheet, scenario.agTx.to.objects)

  #set aggregate Tx to 1 in each region
  #uses regions.to.objects
all.regions <- unique(node.data.table[,RegionName])

agTx.to.properties <- initialize_table(Properties.sheet, 
  length(all.regions), list(parent_class = "System", 
    child_class = "Region", collection = "Regions", parent_object = "System", 
    band_id = 1, property = "Aggregate Transmission", value = -1,
    scenario = "{Object}Aggregate transmission in all regions"))

agTx.to.properties[, child_object := all.regions]

Properties.sheet <- merge_sheet_w_table(Properties.sheet, agTx.to.properties)

# add one node as reference node to every region
# uses node.data.table, remap.reference.nodes, map.ref.node.file

# if there is an external file and this option is turned on, grab it and 
# note and regions that aren't included
if (exists('remap.reference.nodes')) {
  if (remap.reference.nodes == TRUE) {
    if (file.exists(file.path(inputfiles.dir, map.ref.node.file))) {
      
      external.refnode <- fread(file.path(inputfiles.dir, map.ref.node.file))
      
      # keep track of what regions aren't in this file to assign ref node to them
      other.regions <- node.data.table[,unique(RegionName)]
      other.regions <- other.regions[!(other.regions %in% 
                                       external.refnode[,unique(Region)])]
      
    }} else {
      message(paste('... remap.reference.nodes is FALSE.',
                    'Assigning first node in each region as reference node'))
      other.regions <- node.data.table[,unique(RegionName)]
    }
} else {
  message(paste('... remap.reference.nodes or doesn\'t exist.',
                'Assigning first node in each region as reference node'))
  other.regions <- node.data.table[,unique(RegionName)]
}

# for any missing regions, grab a reference node and output full table, 
# then combine all refnode tables so that all info is contained in 
# ref.node.region.table
if (length(other.regions) > 0) {
  
  message(sprintf('... Assigning reference node as first node in %s', 
    paste0(other.regions, collapse = ', ')))
  ref.node.region.table <- node.data.table[RegionName %in% other.regions, 
    .(Region = RegionName, `Region.Reference Node` = BusName)]
  ref.node.region.table <- ref.node.region.table[!duplicated(Region),]
  
  if (exists('external.refnode')) {
    ref.node.region.table <- merge(ref.node.region.table, external.refnode, 
      by = c('Region', 'Region.Reference Node'), all = T)
  } 
} else {
  ref.node.region.table <- external.refnode
}

agTx.refnode.region.to.memberships <- initialize_table(Memberships.sheet, 
  nrow(ref.node.region.table), list(parent_class = "Region", 
    child_class = "Node", collection = "Reference Node"))
agTx.refnode.region.to.memberships[, parent_object := 
    ref.node.region.table[,Region]]
agTx.refnode.region.to.memberships[, child_object := 
    ref.node.region.table[,`Region.Reference Node`]]

Memberships.sheet <- merge_sheet_w_table(Memberships.sheet, 
  agTx.refnode.region.to.memberships)

# clean up
rm(ref.node.region.table, agTx.refnode.region.to.memberships, other.regions, 
  scenario.agTx.to.objects, agTx.to.properties)

#------------------------------------------------------------------------------|
# [[Tx onfiguration]] Add scen. tag to interfaces ----
# -----------------------------------------------------------------------------|

# ---- ZONAL INTERFACES
interface.names <- Objects.sheet[class == "Interface" & 
  category == 'Zonal interfaces', name]
  
  # add dummy min up, min down, start costs to objects
interf.scen.to.objects <- initialize_table(Objects.sheet, 1, 
  list(class = "Scenario", name = "Include zonal interfaces", 
  category = "Transmission configuration"))
Objects.sheet <- merge_sheet_w_table(Objects.sheet, interf.scen.to.objects)

  # add scenario tag to these properties
  # uses interface.names
interf.off.to.properties <- initialize_table(Properties.sheet, 
  length(interface.names), list(parent_class = "System", parent_object = "System", 
    collection = "Interfaces", child_class = "Interface", band_id = 1, 
    child_object = interface.names, property = "Units", value = 0))

interf.scen.to.properties <- initialize_table(Properties.sheet, 
  length(interface.names), list(parent_class = "System", parent_object = "System", 
    collection = "Interfaces", child_class = "Interface", band_id = 1, 
    child_object = interface.names, property = "Units", 
    value = 1, scenario = "{Object}Include zonal interfaces"))

Properties.sheet <- merge_sheet_w_table(Properties.sheet, 
  interf.scen.to.properties)
Properties.sheet <- merge_sheet_w_table(Properties.sheet, 
  interf.off.to.properties)

# ---- REGIONAL INTERFACES
interface.names <- Objects.sheet[class == "Interface" & 
  category == 'Regional interfaces', name]

  # add dummy min up, min down, start costs to objects
interf.scen.to.objects <- initialize_table(Objects.sheet, 1, 
  list(class = "Scenario", name = "Include regional interfaces", 
  category = "Transmission configuration"))
Objects.sheet <- merge_sheet_w_table(Objects.sheet, interf.scen.to.objects)

  # add scenario tag to these properties
  # uses interface.names
interf.off.to.properties <- initialize_table(Properties.sheet, 
  length(interface.names), list(parent_class = "System", parent_object = "System", 
    collection = "Interfaces", child_class = "Interface", band_id = 1, 
    child_object = interface.names, property = "Units", value = 0))

interf.scen.to.properties <- initialize_table(Properties.sheet, 
  length(interface.names), list(parent_class = "System", parent_object = "System", 
    collection = "Interfaces", child_class = "Interface", band_id = 1, 
    child_object = interface.names, property = "Units", 
    value = 1, scenario = "{Object}Include regional interfaces"))

Properties.sheet <- merge_sheet_w_table(Properties.sheet, 
  interf.scen.to.properties)
Properties.sheet <- merge_sheet_w_table(Properties.sheet, 
  interf.off.to.properties)

#------------------------------------------------------------------------------|
# [[Tx configuration]] Don't enforce intERstate lines ----
# -----------------------------------------------------------------------------|
  # scneario to objects
scenario.no.intrastate.lines <- initialize_table(Objects.sheet, 1, 
  list(class = "Scenario", name = "Turn off interstate lines", 
  category = "Transmission configuration"))
Objects.sheet <- merge_sheet_w_table(Objects.sheet, 
  scenario.no.intrastate.lines)

  # scenario to properties
  # uses line.data.table
interstate.lines <- line.data.table[grepl("Interstate", category), name]
scenario.no.inters.lines.to.propterties <- 
  initialize_table(Properties.sheet, length(interstate.lines), 
  list(parent_class = "System", child_class = "Line", 
  parent_object = "System", band_id = 1, collection = "Lines"))
scenario.no.inters.lines.to.propterties[,child_object := interstate.lines]
scenario.no.inters.lines.to.propterties[,property := "Enforce Limits"]
scenario.no.inters.lines.to.propterties[,value := "0"]
scenario.no.inters.lines.to.propterties[,
  scenario := "{Object}Turn off interstate lines"]

Properties.sheet <- merge_sheet_w_table(Properties.sheet, 
  scenario.no.inters.lines.to.propterties)


#------------------------------------------------------------------------------|
# [[Tx configuration]] Don't enforce intRAstate lines ----
# -----------------------------------------------------------------------------|
  # scneario to objects
scenario.no.intrastate.lines <- initialize_table(Objects.sheet, 1, 
  list(class = "Scenario", name = "For PsN - don't enforce intrastate lines", 
  category = "Transmission configuration"))
Objects.sheet <- merge_sheet_w_table(Objects.sheet, 
  scenario.no.intrastate.lines)

  # scenario to properties
  # uses line.data.table
intrastate.lines <- line.data.table[!grepl("Interstate", category), name]
scenario.no.intras.lines.to.propterties <- 
  initialize_table(Properties.sheet, length(intrastate.lines), 
  list(parent_class = "System", child_class = "Line", 
  parent_object = "System", band_id = 1, collection = "Lines"))
scenario.no.intras.lines.to.propterties[,child_object := intrastate.lines]
scenario.no.intras.lines.to.propterties[,property := "Enforce Limits"]
scenario.no.intras.lines.to.propterties[,value := "0"]
scenario.no.intras.lines.to.propterties[,
  scenario := "{Object}For PsN - don't enforce intrastate lines"]

Properties.sheet <- merge_sheet_w_table(Properties.sheet, 
  scenario.no.intras.lines.to.propterties)


#------------------------------------------------------------------------------|
# [[Add standard data]] Add standard ratings to lines ----
# -----------------------------------------------------------------------------|
  #scenario to objects
scenario.line.MW.std.to.objects <- initialize_table(Objects.sheet, 1, list(
  class = "Scenario", name = "Add Standard Line Flow Lims", 
  category = "Add standard data"))
Objects.sheet <- merge_sheet_w_table(Objects.sheet, 
  scenario.line.MW.std.to.objects)

# add standard flow limits to lines with ratings of zero
  # uses line.data.table
zero.flow.lines <- line.data.table[RatingB == "0"]
# defines stadards with [name = kV level] = [element = MW flow limit]
standard.flow.lims <- c("132" = "80", "220" = "200", "400" = "870", 
  "765" = "2200", 
  # these next ones are from looking at most commnon flow limits on these lines
  "11" = "30", "33" = "33", "66" = "28", "100" = "80", "110" = "80", 
  "230" = "200",
  #and these ones are rough guesses
  "0.6" = "10", "69" = "30", "115" = "80", "22.9" = "20", "34.5" = "34.5",
  "13.8" = "30", "138" = "150")

max.flow.correction <- initialize_table(Properties.sheet, 
  nrow(zero.flow.lines), list(parent_class = "System", child_class = "Line", 
    collection = "Lines", parent_object =  "System", 
    child_object = zero.flow.lines[,name], band_id = 1, 
    scenario = "{Object}Add Standard Line Flow Lims"))

invisible(lapply(names(standard.flow.lims), function(kV.level) {
  max.flow.correction[(child_object %in% zero.flow.lines[FromKV == 
  kV.level,name]), c("property", "value") := list("Max Flow", 
  standard.flow.lims[[kV.level]] )]  }))

min.flow.correction <- initialize_table(Properties.sheet, 
  nrow(zero.flow.lines), list(parent_class = "System", child_class = "Line", 
    collection = "Lines", parent_object =  "System", 
    child_object = zero.flow.lines[,name], band_id = 1, 
    scenario = "{Object}Add Standard Line Flow Lims"))

invisible(lapply(names(standard.flow.lims), function(kV.level) {
  min.flow.correction[(child_object %in% zero.flow.lines[FromKV == 
    kV.level,name]), c("property", "value") := list("Min Flow", 
    paste0("-",standard.flow.lims[[kV.level]]) )]  }))

Properties.sheet <- merge_sheet_w_table(Properties.sheet, max.flow.correction)
Properties.sheet <- merge_sheet_w_table(Properties.sheet, min.flow.correction)


#------------------------------------------------------------------------------|
# [[Add standard data]] Add standard ratings to transformers ----
# -----------------------------------------------------------------------------|
  #scenario to objects
scenario.tfmr.MW.std.to.objects <- initialize_table(Objects.sheet, 1, list(
  class = "Scenario", name = "Add Standard Tfmr Ratings", 
  category = "Add standard data"))
Objects.sheet <- merge_sheet_w_table(Objects.sheet, 
  scenario.tfmr.MW.std.to.objects)

# add standard flow limits to lines with ratings of zero
# uses transformer.data.table
zero.flow.tfmrs <- transformer.data.table[Rating.MW == 0]
# defines stadards with [name = low kV (kV.To)] = [element = standard rating]
standard.flow.tfmr.lims <- c("230"="500", "220" = "315", "132" = "100", "110" = "100", 
  "66" = "100", "69" = "100", "138" = "100", "13.8" = "100")

tfmr.rating.correction <- initialize_table(Properties.sheet, 
  nrow(zero.flow.tfmrs), list(parent_class = "System", 
    child_class = "Transformer", collection = "Transformers", 
    parent_object =  "System", child_object = zero.flow.tfmrs[,name], 
    band_id = 1, scenario = "{Object}Add Standard Tfmr Ratings"))

invisible(lapply(names(standard.flow.tfmr.lims), function(kV.level) {
  tfmr.rating.correction[(child_object %in% zero.flow.tfmrs[ToKV == 
    kV.level,name]), c("property", "value") := list("Rating", 
    standard.flow.tfmr.lims[[kV.level]])]  }))

Properties.sheet <- merge_sheet_w_table(Properties.sheet, 
  tfmr.rating.correction)


#------------------------------------------------------------------------------|
# IMPORT GENERIC FILES ----
# -----------------------------------------------------------------------------|

#uses generic.import.files

all.sheets <- c("Objects", "Categories", "Memberships", "Attributes", 
  "Properties", "Reports")

  #create temporary function definitions for better readability of double 
  #lapply below
read_tab <- function(file.name) {
    data.table(suppressWarnings(read.csv(file.path(inputfiles.dir, file.name), 
      stringsAsFactors = FALSE, fill = TRUE, header=FALSE, col.names = 
      paste0("V",seq_len(20)), strip.white = TRUE)))
}

import_and_merge <- function(imported.tab, sheet.name) {
    cur.tab <- import_table_generic(imported.tab, sheet.name)
    if (!is.null(cur.tab)) {
      assign(paste0(sheet.name, ".sheet"), merge_sheet_w_table(get(paste0(
        sheet.name,".sheet")), cur.tab), envir = .GlobalEnv)
    } 
}

  #import and merge all generic import files
if (exists('generic.import.files')) {
invisible(lapply(generic.import.files, function (x) {
  
  if (file.exists(file.path(inputfiles.dir,x))) {
    
    message(sprintf("... importing from %s", x))
    
    # read in data, change blanks to NA, and import into .sheet tables
    imported.file <- read_tab(x)
    
    for (j in seq_len(ncol(imported.file)))
        set(imported.file, which(imported.file[[j]] == ""), j, NA)
    
    lapply(all.sheets, function(y) import_and_merge(imported.file, y))
    
  } else {
    
    # warn about file not existing
    message(sprintf(">>  %s does not exist ... skipping", x))
    
  }
}))
} else { message('>>  no generic import files defined ... skipping') }

rm(import_and_merge, read_tab, all.sheets)


#------------------------------------------------------------------------------|
# IMPORT COMPACT GENERIC FILES ----
#------------------------------------------------------------------------------|
   # uses compact.generic.import.files
   # loop through compact generic input files and read in tables

if (exists('compact.generic.import.files')) {
for (i in seq_along(compact.generic.import.files)) {
  if (file.exists(file.path(inputfiles.dir,
                            compact.generic.import.files[[i]][1]))) {
    message(sprintf("... importing from %s", 
                    compact.generic.import.files[[i]][1]))
    
    cur.tab <- fread(file.path(inputfiles.dir, 
                               compact.generic.import.files[[i]][1]))
    
    cur.obj.type <- compact.generic.import.files[[i]][2]
    
    # read in file, add appropriate sections to object, attib, memb .sheet tables
    import_table_compact(cur.tab, cur.obj.type)
    
  } else {
    message(sprintf(">>  %s does not exist ... skipping", 
                    compact.generic.import.files[[i]][1]))
  }
}
} else { message('>>  no compact generic import files defined ... skipping')}
# clean up
rm(cur.tab, cur.obj.type)

if (india.repo){
#------------------------------------------------------------------------------|
# [[Regional]] Make two scenarios: one for each regional study
# -----------------------------------------------------------------------------|
  # prepare for this by getting region-zone mapping
  # assumes that no region has nodes in multiple zones
region.zone <- node.data.table[,list(RegionName = unique(RegionName)), 
  by = "ZoneName"]

# depends on previous AgTx scenario assigning reference nodes. Do this better 
# (at least pick big nodes) later. 

#------------------------------------------------------------------------------|
# [[Regional]] Aggregate transmission scenario: all but SR ----
# -----------------------------------------------------------------------------|
  #scenario to objects
scenario.SR.to.objects <- initialize_table(Objects.sheet, 1, list(
  class = "Scenario", name = "Aggregate non-SR", category = "Regional studies"))
Objects.sheet <- merge_sheet_w_table(Objects.sheet, scenario.SR.to.objects)

  #set aggregate Tx to 1 in each region
  #uses region.zone
scenario.SR.properties <- initialize_table(Properties.sheet, 
  nrow(region.zone[ZoneName != "SR"]), list(parent_class = "System", 
    child_class = "Region", collection = "Regions", parent_object = "System", 
    band_id = 1, property = "Aggregate Transmission", value = -1,
    scenario = "{Object}Aggregate non-SR"))

scenario.SR.properties[, child_object := region.zone[ZoneName != "SR", 
  RegionName]]

Properties.sheet <- merge_sheet_w_table(Properties.sheet, 
  scenario.SR.properties)

#------------------------------------------------------------------------------|
# [[Regional]] [Aggregate transmission scenario: all but WR ----
# -----------------------------------------------------------------------------|
  #scenario to objects
scenario.WR.to.objects <- initialize_table(Objects.sheet, 1, list(
  class = "Scenario", name = "Aggregate non-WR", category = "Regional studies"))
Objects.sheet <- merge_sheet_w_table(Objects.sheet, scenario.WR.to.objects)

  #set aggregate Tx to 1 in each region
  #uses region.zone
  # Include Rajasthan in WR
scenario.WR.properties <- initialize_table(Properties.sheet, 
  nrow(region.zone[ZoneName != "WR"]) - 1, list(parent_class = "System", 
    child_class = "Region", collection = "Regions", parent_object = "System", 
    band_id = 1, property = "Aggregate Transmission", value = -1,
    scenario = "{Object}Aggregate non-WR"))

scenario.WR.properties[, child_object := region.zone[ZoneName != "WR" & 
  RegionName != "CHHATTISGARH" & RegionName != "RAJASTHAN", RegionName]]

Properties.sheet <- merge_sheet_w_table(Properties.sheet, 
  scenario.WR.properties)
}

#------------------------------------------------------------------------------|
# [[Scenario archive for other configs]] Add Max Energy Penalty ----
#------------------------------------------------------------------------------| 
  # scenario to objects
scenario.max.en.penalty <- initialize_table(Objects.sheet, 1, 
  list(class = "Scenario", name = "Add Max Energy Penalty", 
    category = "Scenario archive for other configurations"))
Objects.sheet <- merge_sheet_w_table(Objects.sheet, scenario.max.en.penalty)

  # get the names of all hydro gens that have a Max Energy Month property
max.en.mo.gens <- Properties.sheet[property == "Max Energy Month", child_object]
if (length(max.en.mo.gens)/12 > length(unique(max.en.mo.gens))) {print(
  "STOP! Some gens have too many max energy month assignments.")}

max.en.penalty.to.properties <- initialize_table(Properties.sheet, 
  length(unique(max.en.mo.gens)), list(parent_class = "System", 
  parent_object = "System", collection = "Generators", child_class = "Generator", 
  child_object = unique(max.en.mo.gens), band_id = 1, 
  property = "Max Energy Penalty", value = 10000000000,
  scenario = "{Object}Add Max Energy Penalty"))
Properties.sheet <- merge_sheet_w_table(Properties.sheet, 
  max.en.penalty.to.properties)


#------------------------------------------------------------------------------|
# [[Scenario archive for other configurations]] Set line reactance to zero ----
# -----------------------------------------------------------------------------|
# hopefully, this forces model to run transport instead of DCOPF

  # scneario to objects
scenario.dc.lines <- initialize_table(Objects.sheet, 1, 
  list(class = "Scenario", name = "Make all lines DC", 
  category = "Scenario archive for other configurations"))
Objects.sheet <- merge_sheet_w_table(Objects.sheet, scenario.dc.lines)

  # scenario to properties
  # uses line.data.table
# create table of only AC lines to use
ac.lines <- line.data.table[ACorDC == 'AC']
scenario.dc.lines.to.properties <- initialize_table(Properties.sheet, 
  nrow(ac.lines), list(parent_class = "System", child_class = "Line", 
  parent_object = "System", band_id = 1, collection = "Lines"))
scenario.dc.lines.to.properties[,child_object := ac.lines[,name]]
scenario.dc.lines.to.properties[,property := "Reactance"]
scenario.dc.lines.to.properties[,value := "0"]
scenario.dc.lines.to.properties[,scenario := "{Object}Make all lines DC"]

Properties.sheet <- merge_sheet_w_table(Properties.sheet, 
  scenario.dc.lines.to.properties)


#------------------------------------------------------------------------------|
# [[Scenario archive for other configs]] Lines to enforce for natnl study ----
# -----------------------------------------------------------------------------|
if (exists('enforced.interstate.lines.file')) {
 if (file.exists(file.path(inputfiles.dir,
                            enforced.interstate.lines.file))) {
    message(sprintf("... enforcing lines from  %s", 
                    enforced.interstate.lines.file))
    
    # scneario to objects
    scenario.interstate.lines <- 
      initialize_table(Objects.sheet, 1, 
                       list(class = "Scenario", 
                        name = "For PsN - fewer interstate lines to enforce", 
                        category = "Scenario archive for other configurations"))
    Objects.sheet <- merge_sheet_w_table(Objects.sheet, 
                                         scenario.interstate.lines)
    
    # scenario to properties
    # uses line.data.table
    interstate.to.enf <- fread(file.path(inputfiles.dir,
                                         enforced.interstate.lines.file))
    
    scenario.enf.interstate.lines.to.propterties <- 
      initialize_table(Properties.sheet, nrow(interstate.to.enf), 
                       list(parent_class = "System", child_class = "Line", 
                            parent_object = "System", band_id = 1, 
                            collection = "Lines"))
    scenario.enf.interstate.lines.to.propterties[,child_object := 
                                                interstate.to.enf[,Line.Name]]
    scenario.enf.interstate.lines.to.propterties[,property := "Enforce Limits"]
    scenario.enf.interstate.lines.to.propterties[,value := "2"] # always
    scenario.enf.interstate.lines.to.propterties[,scenario := 
                 "{Object}For PsN - fewer interstate lines to enforce"]
    
    Properties.sheet <- merge_sheet_w_table(Properties.sheet, 
                        scenario.enf.interstate.lines.to.propterties)
    
  } else {
    message(sprintf(">>  %s does not exist ... skipping", 
                    enforced.interstate.lines.file))
  }
} else {
  message(">>  enforced.interstate.lines.file does not exist ... skipping")
}

#------------------------------------------------------------------------------|
# [[Scen arx for other configs]] Rmve isolated nodes, recalc LPF for others ----
# -----------------------------------------------------------------------------|
if (exists('isolated.nodes.to.remove.args.list')) {
    for (i in seq_along(isolated.nodes.to.remove.args.list)) {
        # pull element from the list
        isolated.nodes.to.remove.args = isolated.nodes.to.remove.args.list[[i]]
        
        # get file, scenario, and category names
        isolated.nodes.to.remove.file = isolated.nodes.to.remove.args[1]
        cur.scenario = isolated.nodes.to.remove.args["scenario"]
        cur.category = isolated.nodes.to.remove.args["category"]
        
        if (file.exists(file.path(inputfiles.dir,
                                isolated.nodes.to.remove.file))) {
        if (is.null(cur.scenario))
            cur.scenario = NA
        
        if (is.null(cur.category))
          cur.category = NA
        
        message(sprintf("... removing isolated nodes from  %s in scenario %s in category %s", 
                        isolated.nodes.to.remove.file,
                        cur.scenario,
                        cur.category))
        
        if (!is.na(cur.scenario)) {
          # scenario to objects
          scenario.remove.isolated <- 
            initialize_table(Objects.sheet, 1, 
                             list(class = "Scenario", 
                                  name = cur.scenario, 
                                  category = cur.category))
          
          Objects.sheet <- merge_sheet_w_table(Objects.sheet, 
                                               scenario.remove.isolated)
        }
        
        # scenario to properties
        # uses isolated.nodes.to.remove.file
        # read in isolated nodes to remove file and change it to a veector
        isolated.nodes.to.remove = fread(file.path(inputfiles.dir,
                                                   isolated.nodes.to.remove.file))
        isolated.nodes.to.remove[,Units:="0"]
        
        if(!is.na(cur.scenario)){
            add_to_properties_sheet(isolated.nodes.to.remove, names.col = "Node.Name", 
                                    object.class = "Node", collection.name =  "Nodes",
                                    scenario.name = cur.scenario)
        } else {
            add_to_properties_sheet(isolated.nodes.to.remove, names.col = "Node.Name", 
                                    object.class = "Node", collection.name =  "Nodes",
                                    overwrite = TRUE)
        }

        # recalculate relevant LPFs for other nodes 
        # pull node LPFs in base case (no scenario) from properties sheet for all 
        # nodes except the ones to be removed
        redo.lpfs.to.properties <- 
          Properties.sheet[property == "Load Participation Factor" & 
                           !(child_object %in% isolated.nodes.to.remove$Node.Name) &
                           is.na(scenario), 
                           .(BusName = child_object, value)]
        
        # add region for calculating LPF
        redo.lpfs.to.properties <-
          merge(redo.lpfs.to.properties, node.data.table[,.(BusName, RegionName)], 
                by = "BusName")
        
        # recalculate LPF
        redo.lpfs.to.properties[,`Load Participation Factor` := prop.table(as.numeric(value)), 
                                by = "RegionName"]
        redo.lpfs.to.properties <- redo.lpfs.to.properties[value != `Load Participation Factor`]
        
        # for nodes with LPFs that have changed, assign the new LPFs to the nodes
        # and attach the scenario
        redo.lpfs.to.properties[, c("value", "RegionName") := NULL]
        
        if(!is.na(cur.scenario)){
            add_to_properties_sheet(redo.lpfs.to.properties, names.col = "BusName", 
                                    object.class = "Node", collection.name =  "Nodes",
                                    scenario.name = cur.scenario)
        } else {
            add_to_properties_sheet(redo.lpfs.to.properties, names.col = "BusName", 
                                    object.class = "Node", collection.name =  "Nodes",
                                    overwrite = TRUE)
        }
        
        } else {
        message(sprintf(">>  %s does not exist ... skipping", 
                        isolated.nodes.to.remove.file))
                    
        # clean up
        rm(cur.category, cur.scenario, redo.lpfs.to.properties, 
            isolated.nodes.to.remove.args, isolated.nodes.to.remove, 
            scenario.remove.isolated)
        
  }}} else {
    message(">>  isolated.nodes.to.remove.file does not exist ... skipping")
  }


    
#------------------------------------------------------------------------------|
# [[user defined constraint import]]                                       ----
# -----------------------------------------------------------------------------|
# 
if (exists('constraint.import.files')) {
  for (i in seq_along(constraint.import.files)) {
    if (file.exists(file.path(inputfiles.dir,
                              constraint.import.files[[i]][1]))) {
      message(sprintf("... importing constraint from  %s", 
                      constraint.import.files[[i]][1]))
      #data.table(read.csv(file.path(inputfiles.dir, filename)))
      import_constraint(fread(file.path(inputfiles.dir, 
                                 constraint.import.files[[i]][1])))
    } else {
      message(sprintf(">>  %s does not exist ... skipping", 
                      constraint.import.files[[i]][1]))
    }
  }
} else { message('>>  no constraint import files defined ... skipping')}


#------------------------------------------------------------------------------|
# Import model interleave                                       ----
#------------------------------------------------------------------------------|

if (exists("interleave.models.list")) {
    # go through all files in this list
    for (item in interleave.models.list) {
        cur.fname = item[1]
        cur.template.fuel.name = item[["template.fuel"]]
        cur.template.object.name = item[["template.object"]]
        
        # make sure interleave file and template file both exist 
        if (all(
            file.exists(file.path(inputfiles.dir, cur.fname)) & 
            file.exists(file.path(inputfiles.dir, cur.template.fuel.name)) &
            ifelse(!is.null(cur.template.object.name[1]), 
                file.exists(file.path(inputfiles.dir, cur.template.object.name)),
                TRUE) # only check for cur.template.obj if it exists
            )) {
            
            if (is.null(cur.template.object.name[1])) {
                message(sprintf("... interleaving models in %s, using template in %s",
                                cur.fname, cur.template.fuel.name))
            } else {
                message(sprintf("... interleaving models in %s, using templates in %s and %s",
                                cur.fname, cur.template.fuel.name, 
                                paste0(cur.template.object.name, collapse = ", ")))
            }
           
            # do actual work  
            # parse this file
            cur.tab = fread(file.path(inputfiles.dir, cur.fname))
            cur.template.fuel = fread(file.path(inputfiles.dir, cur.template.fuel.name))
            
            # if cur.template.object exists, grab it, handling as a list since
            # could be any number of templates
            if (!is.null(cur.template.object.name[1])) (
                cur.template.object = lapply(cur.template.object.name, 
                                             function(x) fread(file.path(inputfiles.dir, x)))
            )
            
            # need to make a datafile object for each property to be passed down
            # it will have filepointers to the datafile to be passed, in 
            # scenarios.
            # this datafile object will be attached with no scenario to that 
            # property of all applicable objects
            # NOTE tihs means that this formulation does not currently support
            #   one scenario where a property is passed to all generators and
            #   another scenario where the same property is passed to only half
            #   the generators (since the datafile object will be attached to
            #   all of the generators)
            
            # ---- first, process templates
            
            # look at all templates and check whether all datafile objects 
            # already exist. if they don't, create them.
            # objects will always be named "Pass _____ property" 
            # properties are in column names of templates
            all.propnames = colnames(cur.template.fuel[,.SD, .SDcols = -1])
            if (!is.null(cur.template.object.name)) {
                all.propnames = c(all.propnames, 
                    sapply(cur.template.object, 
                           function(x) colnames(x[,.SD, .SDcols = -1])))
            }
            
            all.propnames = paste("Pass", all.propnames, "property")
            
            # check if any of these datafile objets aren't in objects sheet. 
            # if they aren't, add them
            missing.propnames = all.propnames[
                !(all.propnames %in% Objects.sheet[class == "Data File", name])]
            
            if (length(missing.propnames) > 0) {
                dfobj.to.obects = initialize_table(Objects.sheet, 
                    length(missing.propnames), list(class = "Data File",
                        name = missing.propnames, category = "Pass properties"))
                
                Objects.sheet <- merge_sheet_w_table(Objects.sheet, dfobj.to.obects)
                
                rm(dfobj.to.obects)
            }
            
            # change blanks to NAs (easier to handle) and check that template 
            # doesn't have more than one file pointer per col
            for (j in seq_len(ncol(cur.template.fuel)))
                set(cur.template.fuel,which(cur.template.fuel[[j]] == ""),j,NA)
            
            if (cur.template.fuel[,
                any(sapply(.SD, function(x) length(unique(na.omit(x))) > 1)), .SDcols = -1]) {
                
                message(sprintf(paste(">>  all filepointers in template %s are",
                    "not identical. this will not be read correctly ... skipping"),
                    cur.template.fuel.name))
                
                cur.template.fuel <- NA
            }
            
            # same, but for object templates if they exist
            if (!is.null(cur.template.object.name)) {
                for (i in seq_along(cur.template.object)) {
                    
                    for (j in seq_len(ncol(i)))
                        set(i,which(i[[j]] == ""),j,NA)
                    
                    if (cur.template.object[[i]][,
                        any(sapply(.SD, function(x) length(unique(na.omit(x))) > 1)), .SDcols = -1]) {
                        
                        message(sprintf(paste(">>  all filepointers in template %s are",
                            "not identical. this will not be read correctly ... skipping"),
                            cur.template.object.name[i]))
                        
                        cur.template.object[[i]] <- NA
                    }
                }
                rm(i,j)
            }
            
            # ---- second, interleave models using templates
            
            for (i in 1:nrow(cur.tab)) {
                # pass to function that will add filepointers to datafile 
                # objects under the right scenario and add datafile objects to 
                # properties (with no scenario) if they aren't already there
                # NOTE this will overwrite data in these properties that is
                #   already defined
                make_interleave_pointers(
                    parent.model = cur.tab[i, parent.model],
                    child.model = cur.tab[i, child.model],
                    filepointer.scenario = cur.tab[i, filepointer.scenario],
                    datafileobj.scenario = cur.tab[i, datafileobj.scenario],
                    template.fuel = cur.template.fuel,
                    template.object = ifelse(exists("cur.template.object"), 
                                             cur.template.object, NA))
            }
            
            # rm(cur.fname, cur.template.fuel, cur.tab, 
            # all.propnames, missing.propnames, cur.template.fuel.name,
            # cur.template.object.name)
            # 
            # if (exists("cur.template.object)) rm(cur.template.object)
            
        } else {
            if (is.null(cur.template.object.name)) {
                message(sprintf(">>  %s or %s does not exist ... skipping", 
                                cur.fname, cur.template.fuel.name))
            } else 
               message(sprintf(">>  %s or %s or %s does not exist ... skipping", 
                                cur.fname, cur.template.fuel.name, paste0(cur.template.object.name, collapse = ", ")))
        }
    }
} else {
    message('>>  interleave.models.list does not exist ... skipping')
}
