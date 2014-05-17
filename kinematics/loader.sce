// =======================================================================================
// loader.sce
// =======================================================================================

// Load general functions
pathName = get_absolute_file_path( "loader.sce" );
getd( pathName );

// Load specific kinematics
exec(pathName + "delta-2_robot/loader.sce", -1) 
exec(pathName + "delta-3_robot/loader.sce", -1) 

// =======================================================================================

