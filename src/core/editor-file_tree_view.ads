with Ada.Strings.Unbounded;
with Editor.File_Tree;

package Editor.File_Tree_View is

   type File_Tree_View_Config is record
      Enabled                  : Boolean := True;
      Default_Width_In_Columns : Natural := 28;
      Minimum_Width_In_Columns : Natural := 16;
      Maximum_Width_In_Columns : Natural := 60;
      Splitter_Width_In_Pixels : Natural := 4;
      Indent_In_Columns        : Natural := 2;
      Show_Root                : Boolean := True;
      Show_Indent_Guides       : Boolean := False;
      Show_Expansion_Markers   : Boolean := True;
   end record;

   type File_Tree_View_State is record
      Width_In_Columns   : Natural := 28;
      Selected_Row_Index : Natural := 0;
      Top_Row            : Natural := 1;
   end record;

   type File_Tree_Row_Direction is
     (Previous_Row,
      Next_Row);


   type File_Tree_View_Zone is
     (Outside_File_Tree,
      File_Tree_Background_Zone,
      File_Tree_Row_Zone,
      File_Tree_Expansion_Zone,
      File_Tree_Label_Zone);

   type File_Tree_Geometry is record
      X      : Integer := 0;
      Y      : Integer := 0;
      Width  : Natural := 0;
      Height : Natural := 0;
   end record;

   type File_Tree_Hit_Result is record
      Zone    : File_Tree_View_Zone := Outside_File_Tree;
      Row     : Natural := 0;
      Node_Id : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
   end record;

   type File_Tree_Action is
     (No_File_Tree_Action,
      Toggle_Directory_Action,
      Open_File_Action);

   type File_Tree_Row_Visual_State is
     (Normal_Row,
      Active_File_Row,
      Directory_Row,
      Expanded_Directory_Row,
      Collapsed_Directory_Row);

   type File_Tree_Visible_Row_Info is record
      Node_Id        : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Depth          : Natural := 0;
      Text           : Ada.Strings.Unbounded.Unbounded_String;
      Is_Directory   : Boolean := False;
      Is_Expanded    : Boolean := False;
      Is_Active_File : Boolean := False;
   end record;


   procedure Clear_View
     (View : in out File_Tree_View_State);

   function Selected_Row_Index
     (View : File_Tree_View_State) return Natural;

   procedure Set_Selected_Row_Index
     (View  : in out File_Tree_View_State;
      Index : Natural);

   function Top_Row
     (View : File_Tree_View_State) return Natural;

   procedure Set_Top_Row
     (View : in out File_Tree_View_State;
      Row  : Natural);

   procedure Ensure_Valid_Selection
     (View : in out File_Tree_View_State;
      Tree : Editor.File_Tree.File_Tree_State);

   procedure Move_Selection
     (View      : in out File_Tree_View_State;
      Tree      : Editor.File_Tree.File_Tree_State;
      Direction : File_Tree_Row_Direction;
      Wrap      : Boolean := False);

   procedure Move_Selection_By
     (View  : in out File_Tree_View_State;
      Tree  : Editor.File_Tree.File_Tree_State;
      Step_Delta : Integer);

   function Node_For_Row
     (Tree      : Editor.File_Tree.File_Tree_State;
      Row_Index : Natural;
      Found     : out Boolean)
      return Editor.File_Tree.File_Tree_Node_Id;

   function Row_For_Node
     (Tree    : Editor.File_Tree.File_Tree_State;
      Node_Id : Editor.File_Tree.File_Tree_Node_Id;
      Found   : out Boolean) return Natural;

   procedure Ensure_Selected_Row_Visible
     (View              : in out File_Tree_View_State;
      Tree              : Editor.File_Tree.File_Tree_State;
      Visible_Row_Count : Natural);

   procedure Clamp_Viewport
     (View              : in out File_Tree_View_State;
      Tree              : Editor.File_Tree.File_Tree_State;
      Visible_Row_Count : Natural);

   procedure Scroll_By
     (View              : in out File_Tree_View_State;
      Tree              : Editor.File_Tree.File_Tree_State;
      Visible_Row_Count : Natural;
      Step_Delta             : Integer);

   procedure Select_First_Visible_Row
     (View : in out File_Tree_View_State;
      Tree : Editor.File_Tree.File_Tree_State);

   procedure Select_Last_Visible_Row
     (View : in out File_Tree_View_State;
      Tree : Editor.File_Tree.File_Tree_State);

   function Current_Config return File_Tree_View_Config;

   function Current_State return File_Tree_View_State;

   procedure Set_Current_Config
     (Config : File_Tree_View_Config);

   procedure Set_Current_State
     (State : File_Tree_View_State);

   procedure Reset;

   function Enabled
     (Config : File_Tree_View_Config) return Boolean;

   function Clamp_Width_In_Columns
     (Config : File_Tree_View_Config;
      Width  : Natural) return Natural;

   procedure Set_Width_In_Columns
     (State  : in out File_Tree_View_State;
      Config : File_Tree_View_Config;
      Width  : Natural);

   function Width_In_Columns
     (Config : File_Tree_View_Config) return Natural;

   function Effective_Width_In_Columns
     (Config : File_Tree_View_Config;
      State  : File_Tree_View_State) return Natural;

   function Current_Width_In_Columns return Natural;

   procedure Set_Current_Width_In_Columns
     (Width : Natural);

   function Width_In_Pixels
     (Config     : File_Tree_View_Config;
      Cell_Width : Natural) return Natural;

   function Width_In_Pixels
     (Config     : File_Tree_View_Config;
      State      : File_Tree_View_State;
      Cell_Width : Natural) return Natural;

   function Splitter_Width_In_Pixels
     (Config : File_Tree_View_Config) return Natural;


   function Hit_Test
     (Geometry : File_Tree_Geometry;
      Config   : File_Tree_View_Config;
      Tree     : Editor.File_Tree.File_Tree_State;
      X        : Integer;
      Y        : Integer) return File_Tree_Hit_Result;

   function Hit_Test
     (Geometry : File_Tree_Geometry;
      Config   : File_Tree_View_Config;
      Tree     : Editor.File_Tree.File_Tree_State;
      State    : File_Tree_View_State;
      X        : Integer;
      Y        : Integer) return File_Tree_Hit_Result;

   function Action_For_Hit
     (Config : File_Tree_View_Config;
      Tree   : Editor.File_Tree.File_Tree_State;
      Hit    : File_Tree_Hit_Result) return File_Tree_Action;

   function Action_For_Summary
     (Summary : Editor.File_Tree.File_Tree_Node_Summary;
      Zone    : File_Tree_View_Zone) return File_Tree_Action;

   function Safe_Display_Label
     (Node : Editor.File_Tree.File_Tree_Node_Summary) return String;

   function Empty_State_Text return String;

   function Format_Row_Text
     (Config : File_Tree_View_Config;
      Node   : Editor.File_Tree.File_Tree_Node_Summary;
      Width  : Natural) return String;

   function Visible_Row_Summary
     (Config    : File_Tree_View_Config;
      Tree      : Editor.File_Tree.File_Tree_State;
      Row_Index : Positive) return Editor.File_Tree.File_Tree_Node_Summary;

   function Truncate_Label
     (Label       : String;
      Max_Columns : Natural) return String;

end Editor.File_Tree_View;
