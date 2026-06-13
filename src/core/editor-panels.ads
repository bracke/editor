package Editor.Panels is

   type Panel_Id is
     (File_Tree_Panel,
      Right_Sidebar_Panel,
      Bottom_Panel);

   type Panel_Side is
     (Left_Side,
      Right_Side,
      Bottom_Side);

   type Panel_Size_Unit is
     (Columns,
      Rows,
      Pixels);

   type Bottom_Panel_Content is
     (Problems_Content,
      Search_Results_Content);

   type Panel_Config is record
      Enabled              : Boolean := False;
      Side                 : Panel_Side := Left_Side;
      Default_Size         : Natural := 0;
      Minimum_Size         : Natural := 0;
      Maximum_Size         : Natural := 0;
      Splitter_Size_Pixels : Natural := 4;
      Size_Unit            : Panel_Size_Unit := Columns;
      Resizable            : Boolean := True;
   end record;

   type Panel_State is record
      Visible      : Boolean := False;
      Current_Size : Natural := 0;
   end record;

   type Panel_Resize_State is record
      Active        : Boolean := False;
      Panel         : Panel_Id := File_Tree_Panel;
      Start_Mouse_X : Integer := 0;
      Start_Mouse_Y : Integer := 0;
      Start_Size    : Natural := 0;
   end record;

   type Panel_Set is private;

   procedure Initialize_Defaults
     (Panels : in out Panel_Set);

   function Default_Set return Panel_Set;

   function Current return Panel_Set;

   procedure Set_Current
     (Panels : Panel_Set);

   function Config
     (Panels : Panel_Set;
      Id     : Panel_Id) return Panel_Config;

   procedure Set_Config
     (Panels : in out Panel_Set;
      Id     : Panel_Id;
      Config : Panel_Config);

   function State
     (Panels : Panel_Set;
      Id     : Panel_Id) return Panel_State;

   procedure Set_Visible
     (Panels  : in out Panel_Set;
      Id      : Panel_Id;
      Visible : Boolean);

   function Is_Visible
     (Panels : Panel_Set;
      Id     : Panel_Id) return Boolean;

   function Current_Size
     (Panels : Panel_Set;
      Id     : Panel_Id) return Natural;

   procedure Set_Current_Size
     (Panels : in out Panel_Set;
      Id     : Panel_Id;
      Size   : Natural);

   function Clamp_Size
     (Config : Panel_Config;
      Size   : Natural) return Natural;

   function Resize_State
     (Panels : Panel_Set) return Panel_Resize_State;

   procedure Begin_Resize
     (Panels  : in out Panel_Set;
      Id      : Panel_Id;
      Mouse_X : Integer;
      Mouse_Y : Integer);

   procedure Update_Resize
     (Panels      : in out Panel_Set;
      Mouse_X     : Integer;
      Mouse_Y     : Integer;
      Cell_Width  : Natural;
      Cell_Height : Natural);

   procedure End_Resize
     (Panels : in out Panel_Set);

   function Resize_Active
     (Panels : Panel_Set) return Boolean;

   procedure Set_Bottom_Content
     (Panels  : in out Panel_Set;
      Content : Bottom_Panel_Content);

   function Active_Bottom_Content
     (Panels : Panel_Set) return Bottom_Panel_Content;

private
   type Config_Array is array (Panel_Id) of Panel_Config;
   type State_Array is array (Panel_Id) of Panel_State;

   type Panel_Set is record
      Configs : Config_Array := (others => (others => <>));
      States  : State_Array := (others => (others => <>));
      Resize  : Panel_Resize_State := (others => <>);
      Bottom_Content : Bottom_Panel_Content := Problems_Content;
   end record;

end Editor.Panels;
