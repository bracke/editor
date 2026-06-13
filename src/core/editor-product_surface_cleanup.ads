with Editor.Commands;
with Editor.State;

package Editor.Product_Surface_Cleanup is

   type Product_Surface_Cleanup_Result is record
      Feature_Panel_Clean      : Boolean := False;
      Outline_Clean            : Boolean := False;
      Diagnostics_Clean        : Boolean := False;
      Command_Surface_Clean    : Boolean := False;
      Build_UI_Clean           : Boolean := False;
      Search_Clean             : Boolean := False;
      Quick_Open_Clean         : Boolean := False;
      File_Tree_Clean          : Boolean := False;
      Coherent                 : Boolean := False;
   end record;

   --  Return True when Text is recognizably test/demo placeholder content.
   --  This is an audit classifier only; it performs no mutation and does not
   --  interpret product empty-state labels as model rows.
   function Looks_Like_Demo_Text (Text : String) return Boolean;

   --  Return True when Id is a command retained only for explicit tests or
   --  fixture scaffolding, and therefore forbidden from normal UI exposure.
   function Is_Test_Only_Command
     (Id : Editor.Commands.Command_Id) return Boolean;

   function Feature_Panel_Has_Demo_Rows
     (S : Editor.State.State_Type) return Boolean;

   function Outline_Has_Fixture_Data
     (S : Editor.State.State_Type) return Boolean;

   function Diagnostics_Has_Demo_Rows
     (S : Editor.State.State_Type) return Boolean;

   function Build_UI_Has_Demo_State
     (S : Editor.State.State_Type) return Boolean;

   function Search_Has_Demo_Results
     (S : Editor.State.State_Type) return Boolean;

   function Quick_Open_Has_Demo_Results
     (S : Editor.State.State_Type) return Boolean;

   function File_Tree_Has_Demo_Nodes
     (S : Editor.State.State_Type) return Boolean;

   function Demo_Command_Exposed_To_Product_Surface return Boolean;

   function Audit_Product_Surface_No_Demo_State
     (S : Editor.State.State_Type) return Product_Surface_Cleanup_Result;

   function Assert_Product_Surface_No_Demo_State_Coherent
     (S : Editor.State.State_Type) return Boolean;

end Editor.Product_Surface_Cleanup;
