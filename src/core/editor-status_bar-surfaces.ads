with Ada.Strings.Unbounded;

package Editor.Status_Bar.Surfaces is

   function Workspace_Surface_Action_Label
     (Surface : Workspace_Status_Surface) return String;

   function Workspace_Surface_Action_Count
     (Surface : Workspace_Status_Surface) return Natural;

   function Quick_Open_Context_Action_Label
     (Surface : Quick_Open_Context_Surface) return String;

   function Quick_Open_Context_Action_Count
     (Surface : Quick_Open_Context_Surface) return Natural;

   function Outline_Surface_Action_Label
     (Surface : Outline_Status_Surface) return String;

   function Outline_Surface_Action_Count
     (Surface : Outline_Status_Surface) return Natural;

   function Search_Replace_Surface_Action_Label
     (Surface : Search_Replace_Status_Surface) return String;

   function Search_Replace_Surface_Action_Count
     (Surface : Search_Replace_Status_Surface) return Natural;

   function File_Tree_Surface_Action_Label
     (Surface : File_Tree_Status_Surface) return String;

   function File_Tree_Surface_Action_Count
     (Surface : File_Tree_Status_Surface) return Natural;

   function Recent_Projects_Surface_Action_Label
     (Surface : Recent_Projects_Status_Surface) return String;

   function Recent_Projects_Surface_Action_Count
     (Surface : Recent_Projects_Status_Surface) return Natural;

   function Workspace_Surface
     (Snapshot : Status_Bar_Snapshot) return Workspace_Status_Surface;

   function Quick_Open_Context_Surface_For
     (Snapshot : Status_Bar_Snapshot) return Quick_Open_Context_Surface;

   function Outline_Surface
     (Snapshot : Status_Bar_Snapshot) return Outline_Status_Surface;

   function Search_Replace_Surface
     (Snapshot : Status_Bar_Snapshot) return Search_Replace_Status_Surface;

   function File_Tree_Surface
     (Snapshot : Status_Bar_Snapshot) return File_Tree_Status_Surface;

   function Recent_Projects_Surface
     (Snapshot : Status_Bar_Snapshot) return Recent_Projects_Status_Surface;

   function Status_Project_File_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Dirty_File_State_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Project_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Focus_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Caret_Selection_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Command_Outcome_Class
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Command_Outcome_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Build_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Diagnostics_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Search_Replace_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Quick_Open_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Outline_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_File_Tree_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Workspace_Recent_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Startup_Segment
     (Snapshot : Status_Bar_Snapshot) return String;

   function Format_Right
     (Snapshot : Status_Bar_Snapshot) return String;

   function Status_Layout_Compact
     (Snapshot    : Status_Bar_Snapshot;
      Max_Columns : Natural) return String;

   function Status_Layout_Should_Use_Compact
     (Snapshot          : Status_Bar_Snapshot;
      Available_Columns : Natural) return Boolean;

end Editor.Status_Bar.Surfaces;
