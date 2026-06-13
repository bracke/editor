with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Recent_Projects is

   type Recent_Project_Status is
     (Recent_Project_Ok,
      Recent_Project_Not_Found,
      Recent_Project_Invalid_Format,
      Recent_Project_Read_Error,
      Recent_Project_Write_Error,
      Recent_Project_Partial_Load);

   type Recent_Project_Entry is record
      Root_Path           : Ada.Strings.Unbounded.Unbounded_String;
      Display_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Last_Opened_Ms      : Natural := 0;
      Is_Unavailable      : Boolean := False;
   end record;

   type Recent_Project_List is private;

   type Recent_Project_Config is record
      Max_Entries : Natural := 20;
   end record;

   Default_Config : constant Recent_Project_Config := (Max_Entries => 20);

   procedure Clear
     (List : in out Recent_Project_List);

   function Count
     (List : Recent_Project_List) return Natural;

   function Available_Count
     (List : Recent_Project_List) return Natural;

   function Unavailable_Count
     (List : Recent_Project_List) return Natural;

   function Item
     (List  : Recent_Project_List;
      Index : Positive) return Recent_Project_Entry;

   procedure Add_Or_Promote
     (List         : in out Recent_Project_List;
      Root_Path    : String;
      Display_Name : String;
      Now_Ms       : Natural;
      Config       : Recent_Project_Config := Default_Config);

   procedure Remove
     (List      : in out Recent_Project_List;
      Root_Path : String);

   procedure Remove_At
     (List  : in out Recent_Project_List;
      Index : Positive);

   function Remove_Missing
     (List : in out Recent_Project_List) return Natural;

   procedure Refresh_Availability
     (List : in out Recent_Project_List);

   function Is_Available
     (Item : Recent_Project_Entry) return Boolean;

   function Path_Label
     (Item : Recent_Project_Entry) return String;

   function Last_Opened_Label
     (Item : Recent_Project_Entry) return String;

   function Unavailable_Label
     (Item : Recent_Project_Entry) return String;

   --  Return the number of malformed or unsupported recent-project entries
   --  ignored by the most recent load. The counter is transient recovery
   --  state and is never serialized into recent-project files.
   function Last_Load_Ignored_Count return Natural;

   function Row_Label
     (Item        : Recent_Project_Entry;
      Is_Selected : Boolean := False) return String;

   procedure Normalize
     (List   : in out Recent_Project_List;
      Config : Recent_Project_Config := Default_Config);

   procedure Save_To_File
     (List   : Recent_Project_List;
      Path   : String;
      Status : out Recent_Project_Status);

   procedure Load_From_File
     (Path   : String;
      List   : out Recent_Project_List;
      Status : out Recent_Project_Status);

   function Normalized_Root_Path
     (Root_Path : String) return String;

   function Recent_Projects_File_Path return String;

   procedure Set_Config_Directory_For_Tests
     (Path : String);

   procedure Clear_Config_Directory_Override;


private
   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Recent_Project_Entry);

   type Recent_Project_List is record
      Entries : Entry_Vectors.Vector;
   end record;

end Editor.Recent_Projects;
