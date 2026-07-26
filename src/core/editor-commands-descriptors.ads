with Editor.Command_Ids; use Editor.Command_Ids;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Commands.Descriptors is

   use Ada.Strings.Unbounded;

   type Command_Category is
     (File_Category,
      Project_Category,
      Edit_Category,
      Selection_Category,
      Navigation_Category,
      Search_Category,
      Panel_Category,
      View_Category,
      Diagnostics_Category,
      Bookmarks_Category,
      Overlay_Category,
      Message_Category,
      Theme_Category,
      Settings_Category,
      Workspace_Category,
      Internal_Category);

   type Command_Visibility is
     (Hidden_Command,
      Palette_Command);

   type Command_Family_Id is
     (No_Command_Family,
      File_Lifecycle_Family);

   type Command_Effect_Classification_Id is
     (No_Command_Effect,
      Writes_Buffer_Text_To_Associated_File,
      Writes_Buffer_Text_To_Explicit_Target_And_Associates,
      Closes_Active_Buffer,
      Reopens_Safe_File_Reference,
      Rereads_Associated_File,
      Discards_Unsaved_Changes_And_Rereads,
      Renames_Associated_File,
      Deletes_Associated_File,
      Copies_Associated_File,
      Moves_Associated_File);

   type Command_Descriptor is record
      Id          : Command_Id := No_Command;
      Name        : Unbounded_String := Null_Unbounded_String;
      Description : Unbounded_String := Null_Unbounded_String;
      Category    : Command_Category := Internal_Category;
      Visibility  : Command_Visibility := Hidden_Command;
      Bindable    : Boolean := False;
      Destructive : Boolean := False;
      Lifecycle   : Boolean := False;
      Configuration : Boolean := False;
      Summary : Unbounded_String := Null_Unbounded_String;
      Availability_Summary : Unbounded_String := Null_Unbounded_String;
      Mutation_Summary : Unbounded_String := Null_Unbounded_String;
      Filesystem_Effect_Summary : Unbounded_String := Null_Unbounded_String;
      State_Preservation_Summary : Unbounded_String := Null_Unbounded_String;
      Non_Goal_Summary : Unbounded_String := Null_Unbounded_String;
      Requires_Explicit_Target : Boolean := False;
      Target_Prompt_Capable : Boolean := False;
      Target_Prompt_Label : Unbounded_String := Null_Unbounded_String;
      Family : Command_Family_Id := No_Command_Family;
      Effect_Classification : Command_Effect_Classification_Id := No_Command_Effect;
   end record;

   package Command_Descriptor_Vectors is new
     Ada.Containers.Vectors
       (Index_Type   => Natural,
        Element_Type => Command_Descriptor);

   function Make_Command_Descriptor
     (Id             : Command_Id;
      Stable_Name    : String;
      Label          : String;
      Description    : String;
      Category       : Command_Category;
      Visible        : Boolean;
      Bindable       : Boolean;
      Destructive    : Boolean := False;
      Lifecycle      : Boolean := False;
      Configuration  : Boolean := False)
      return Command_Descriptor;

   function Descriptor
     (Id : Command_Id) return Command_Descriptor;

   function Label
     (Id : Command_Id) return String;

   function Category
     (Id : Command_Id) return Command_Category;

   function Category_Label
     (Category : Command_Category) return String;

   function Discoverability_Category_Label
     (Id : Command_Id) return String;

   function Classification_Label
     (Id : Command_Id) return String;

   function Surface_Relevance_Label
     (Id : Command_Id) return String;

   function Guard_Label
     (Id : Command_Id) return String;

   function Palette_Commands return Command_Descriptor_Vectors.Vector;

end Editor.Commands.Descriptors;
