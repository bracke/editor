with Ada.Characters.Handling;
with Ada.Containers;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Call_Profile_Shapes;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Representation_Legality.Core_Utilities;
with Editor.Ada_Representation_Legality.Clause_Classification;
with Editor.Ada_Representation_Legality.Target_Compatibility;
with Editor.Ada_Representation_Legality.Static_Value_Checks;
with Editor.Ada_Representation_Legality.Enumeration_Checks;
with Editor.Ada_Representation_Legality.Record_Component_Checks;
with Editor.Ada_Representation_Legality.Interfacing_Checks;
with Editor.Ada_Representation_Legality.Stream_Profile_Checks;

package body Editor.Ada_Representation_Legality is

   pragma Suppress (Overflow_Check);

   use type Ada.Containers.Count_Type;
   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Freezing_Points.Freezable_Id;
   use type Editor.Ada_Freezing_Points.Freezable_Kind;
   use type Editor.Ada_Freezing_Points.Representation_Freezing_Status;
   use type Editor.Ada_Freezing_Points.Freezing_Status;
   use type Editor.Ada_Static_Expressions.Static_Value_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Syntax_Tree.Node_Kind;
   use type Editor.Ada_Type_Graph.Type_Category;
   use type Editor.Ada_Type_Graph.Type_Id;
   use type Editor.Ada_Language_Model.Representation_Clause_Kind;
   use type Editor.Ada_Language_Model.Representation_Source_Form;

   function Mix (A, B : Natural) return Natural
     renames Editor.Ada_Representation_Legality.Core_Utilities.Mix;

   function Trimmed (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Trimmed;

   function Lower (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Lower;

   function Normalized (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Normalized;

   function Child_Label
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Parent : Editor.Ada_Syntax_Tree.Node_Id;
      Kind   : Editor.Ada_Syntax_Tree.Node_Kind) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Child_Label;

   function Attribute_Name (Target_Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Attribute_Name;

   function Strip_Leading_At (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Strip_Leading_At;

   function Range_First (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Range_First;

   function Range_Last (Text : String) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Range_Last;

   function Ancestor_Representation_Clause
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return Editor.Ada_Syntax_Tree.Node_Id
     renames Editor.Ada_Representation_Legality.Core_Utilities.Ancestor_Representation_Clause;

   function Declaration_Name
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return String
     renames Editor.Ada_Representation_Legality.Core_Utilities.Declaration_Name;

   function Name_List_Contains (List_Text, Name : String) return Boolean
     renames Editor.Ada_Representation_Legality.Core_Utilities.Name_List_Contains;

   function Has_Record_Component
     (Tree           : Editor.Ada_Syntax_Tree.Tree_Type;
      Record_Type    : Editor.Ada_Syntax_Tree.Node_Id;
      Component_Name : String) return Boolean
     renames Editor.Ada_Representation_Legality.Core_Utilities.Has_Record_Component;

   function Clause_Kind
     (Target_Text : String;
      Item_Text   : String;
      Full_Text   : String) return Editor.Ada_Language_Model.Representation_Clause_Kind
     renames Editor.Ada_Representation_Legality.Core_Utilities.Clause_Kind;

   function Static_Value_Required
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean
     renames Editor.Ada_Representation_Legality.Clause_Classification.Static_Value_Required;

   function Positive_Value_Required
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean
     renames Editor.Ada_Representation_Legality.Clause_Classification.Positive_Value_Required;

   function Integer_Value_Required
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean
     renames Editor.Ada_Representation_Legality.Clause_Classification.Integer_Value_Required;

   function Interfacing_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean
     renames Editor.Ada_Representation_Legality.Clause_Classification.Interfacing_Clause;

   function Stream_Attribute_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean
     renames Editor.Ada_Representation_Legality.Clause_Classification.Stream_Attribute_Clause;

   function Boolean_Operational_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean
     renames Editor.Ada_Representation_Legality.Clause_Classification.Boolean_Operational_Clause;

   function Order_Operational_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean
     renames Editor.Ada_Representation_Legality.Clause_Classification.Order_Operational_Clause;

   function Operational_Clause
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) return Boolean
     renames Editor.Ada_Representation_Legality.Clause_Classification.Operational_Clause;

   function Aspect_Representation_Name (Name : String) return Boolean
     renames Editor.Ada_Representation_Legality.Clause_Classification.Aspect_Representation_Name;

   function Aspect_Default_Value (Name, Value : String) return String
     renames Editor.Ada_Representation_Legality.Clause_Classification.Aspect_Default_Value;

   function Compatible_Target_Kind
     (Kind     : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Category : Editor.Ada_Type_Graph.Type_Category) return Boolean
     renames Editor.Ada_Representation_Legality.Target_Compatibility.Compatible_Target_Kind;

   function Compatible_Address_Target
     (Kind : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean
     renames Editor.Ada_Representation_Legality.Target_Compatibility.Compatible_Address_Target;

   function Size_Target_Compatible
     (Freezable : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean
     renames Editor.Ada_Representation_Legality.Target_Compatibility.Size_Target_Compatible;

   function Alignment_Target_Compatible
     (Freezable : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean
     renames Editor.Ada_Representation_Legality.Target_Compatibility.Alignment_Target_Compatible;

   function Storage_Size_Target_Compatible
     (Freezable : Editor.Ada_Freezing_Points.Freezable_Kind;
      Category  : Editor.Ada_Type_Graph.Type_Category) return Boolean
     renames Editor.Ada_Representation_Legality.Target_Compatibility.Storage_Size_Target_Compatible;

   function Stream_Target_Compatible
     (Freezable : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean
     renames Editor.Ada_Representation_Legality.Target_Compatibility.Stream_Target_Compatible;

   function Operational_Target_Compatible
     (Kind      : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Freezable : Editor.Ada_Freezing_Points.Freezable_Kind;
      Category  : Editor.Ada_Type_Graph.Type_Category) return Boolean
     renames Editor.Ada_Representation_Legality.Target_Compatibility.Operational_Target_Compatible;

   function Interfacing_Target_Compatible
     (Kind      : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Freezable : Editor.Ada_Freezing_Points.Freezable_Kind) return Boolean
     renames Editor.Ada_Representation_Legality.Target_Compatibility.Interfacing_Target_Compatible;

   function Deepest_Region_Containing_Line
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Line    : Positive) return Editor.Ada_Declarative_Regions.Region_Id
     renames Editor.Ada_Representation_Legality.Target_Compatibility.Deepest_Region_Containing_Line;

   function Ancestor_Declaration_Target
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return String
     renames Editor.Ada_Representation_Legality.Target_Compatibility.Ancestor_Declaration_Target;

   function Freeze_Info_For_Target_At
     (Freezing : Editor.Ada_Freezing_Points.Freezing_Model;
      Regions  : Editor.Ada_Declarative_Regions.Region_Model;
      Line     : Positive;
      Target   : String) return Editor.Ada_Freezing_Points.Representation_Freeze_Info
     renames Editor.Ada_Representation_Legality.Target_Compatibility.Freeze_Info_For_Target_At;

   function Type_Category_For_Target
     (Types   : Editor.Ada_Type_Graph.Type_Model;
      Target  : Editor.Ada_Freezing_Points.Freezable_Info)
      return Editor.Ada_Type_Graph.Type_Category
     renames Editor.Ada_Representation_Legality.Target_Compatibility.Type_Category_For_Target;

   function Is_Known_Convention (Name : String) return Boolean
     renames Editor.Ada_Representation_Legality.Static_Value_Checks.Is_Known_Convention;

   function Is_Identifier_Text (Text : String) return Boolean
     renames Editor.Ada_Representation_Legality.Static_Value_Checks.Is_Identifier_Text;

   function Is_Static_String_Text (Text : String) return Boolean
     renames Editor.Ada_Representation_Legality.Static_Value_Checks.Is_Static_String_Text;

   function Is_Static_Boolean_True (Text : String) return Boolean
     renames Editor.Ada_Representation_Legality.Static_Value_Checks.Is_Static_Boolean_True;

   function Is_Static_Boolean_False (Text : String) return Boolean
     renames Editor.Ada_Representation_Legality.Static_Value_Checks.Is_Static_Boolean_False;

   function Is_High_Order_First (Text : String) return Boolean
     renames Editor.Ada_Representation_Legality.Static_Value_Checks.Is_High_Order_First;

   function Is_Low_Order_First (Text : String) return Boolean
     renames Editor.Ada_Representation_Legality.Static_Value_Checks.Is_Low_Order_First;

   function Operational_Value_Status_For
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Text : String) return Operational_Value_Status
     renames Editor.Ada_Representation_Legality.Static_Value_Checks.Operational_Value_Status_For;

   function Interfacing_Value_Status_For
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Text : String) return Interfacing_Value_Status
     renames Editor.Ada_Representation_Legality.Static_Value_Checks.Interfacing_Value_Status_For;

   function Starts_With_Digit_Or_Sign (Text : String) return Boolean
     renames Editor.Ada_Representation_Legality.Static_Value_Checks.Starts_With_Digit_Or_Sign;

   function Stream_Subprogram_Status_For
     (Kind : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Text : String) return Stream_Subprogram_Status
     renames Editor.Ada_Representation_Legality.Static_Value_Checks.Stream_Subprogram_Status_For;

   function Address_Value_Status_For (Text : String) return Address_Value_Status
     renames Editor.Ada_Representation_Legality.Static_Value_Checks.Address_Value_Status_For;

   function Value_Status_For
     (Value : Editor.Ada_Static_Expressions.Static_Value_Info) return Representation_Value_Status
     renames Editor.Ada_Representation_Legality.Static_Value_Checks.Value_Status_For;

   function Is_Enumeration_Type_Node
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id) return Boolean
     renames Editor.Ada_Representation_Legality.Enumeration_Checks.Is_Enumeration_Type_Node;

   function Enumeration_Definition_Text
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id) return String
     renames Editor.Ada_Representation_Legality.Enumeration_Checks.Enumeration_Definition_Text;

   function Enumeration_Definition_Count (Definition : String) return Natural
     renames Editor.Ada_Representation_Legality.Enumeration_Checks.Enumeration_Definition_Count;

   function Enumeration_Definition_Name_At
     (Definition : String;
      Position   : Positive) return String
     renames Editor.Ada_Representation_Legality.Enumeration_Checks.Enumeration_Definition_Name_At;

   function Enumeration_Literal_Count
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id) return Natural
     renames Editor.Ada_Representation_Legality.Enumeration_Checks.Enumeration_Literal_Count;

   function Enumeration_Literal_Name_At
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Position  : Positive) return String
     renames Editor.Ada_Representation_Legality.Enumeration_Checks.Enumeration_Literal_Name_At;

   function Enumeration_Literal_Exists
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Name      : String) return Boolean
     renames Editor.Ada_Representation_Legality.Enumeration_Checks.Enumeration_Literal_Exists;

   function Enumeration_Literal_Position
     (Tree      : Editor.Ada_Syntax_Tree.Tree_Type;
      Type_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Name      : String) return Natural
     renames Editor.Ada_Representation_Legality.Enumeration_Checks.Enumeration_Literal_Position;

   function Enumeration_Literal_Duplicate
     (Model         : Representation_Legality_Model;
      Parent_Clause : Editor.Ada_Syntax_Tree.Node_Id;
      Normalized_Name : String) return Boolean
     renames Editor.Ada_Representation_Legality.Enumeration_Checks.Enumeration_Literal_Duplicate;

   function Enumeration_Value_Duplicate
     (Model         : Representation_Legality_Model;
      Parent_Clause : Editor.Ada_Syntax_Tree.Node_Id;
      Static_Value  : Long_Long_Integer) return Boolean
     renames Editor.Ada_Representation_Legality.Enumeration_Checks.Enumeration_Value_Duplicate;

   procedure Count_Enumeration_Result
     (Model : in out Representation_Legality_Model;
      Info  : Enumeration_Representation_Legality_Info)
     renames Editor.Ada_Representation_Legality.Enumeration_Checks.Count_Enumeration_Result;

   procedure Add_Enumeration_Check
     (Model           : in out Representation_Legality_Model;
      Tree            : Editor.Ada_Syntax_Tree.Tree_Type;
      Static          : Editor.Ada_Static_Expressions.Static_Model;
      Parent_Info     : Representation_Legality_Info;
      Association     : Editor.Ada_Syntax_Tree.Node_Info;
      Literal_Name    : String;
      Value_Text      : String;
      Expected_Pos    : Natural;
      Target_Type_Node : Editor.Ada_Syntax_Tree.Node_Id)
     renames Editor.Ada_Representation_Legality.Enumeration_Checks.Add_Enumeration_Check;

   procedure Add_Enumeration_Incomplete_Check
     (Model           : in out Representation_Legality_Model;
      Parent_Info     : Representation_Legality_Info;
      Missing_Literal  : String;
      Source_Line      : Positive)
     renames Editor.Ada_Representation_Legality.Enumeration_Checks.Add_Enumeration_Incomplete_Check;

   procedure Add_Enumeration_Representation_Checks
     (Model    : in out Representation_Legality_Model;
      Tree     : Editor.Ada_Syntax_Tree.Tree_Type;
      Types    : Editor.Ada_Type_Graph.Type_Model;
      Static   : Editor.Ada_Static_Expressions.Static_Model;
      Clause   : Editor.Ada_Syntax_Tree.Node_Info;
      Parent_Info : Representation_Legality_Info)
     renames Editor.Ada_Representation_Legality.Enumeration_Checks.Add_Enumeration_Representation_Checks;

   function Component_Duplicate
     (Model         : Representation_Legality_Model;
      Parent_Clause : Editor.Ada_Syntax_Tree.Node_Id;
      Normalized_Name : String) return Boolean
     renames Editor.Ada_Representation_Legality.Record_Component_Checks.Component_Duplicate;

   procedure Count_Component_Result
     (Model : in out Representation_Legality_Model;
      Info  : Record_Component_Legality_Info)
     renames Editor.Ada_Representation_Legality.Record_Component_Checks.Count_Component_Result;

   procedure Add_Record_Component_Check
     (Model    : in out Representation_Legality_Model;
      Tree     : Editor.Ada_Syntax_Tree.Tree_Type;
      Types    : Editor.Ada_Type_Graph.Type_Model;
      Static   : Editor.Ada_Static_Expressions.Static_Model;
      Node     : Editor.Ada_Syntax_Tree.Node_Info)
     renames Editor.Ada_Representation_Legality.Record_Component_Checks.Add_Record_Component_Check;

   function Import_Export_Enabled_For_Target
     (Model  : Representation_Legality_Model;
      Target : String) return Boolean
     renames Editor.Ada_Representation_Legality.Interfacing_Checks.Import_Export_Enabled_For_Target;

   function Has_Opposite_Enabled_Import_Export
     (Model : Representation_Legality_Model;
      Info  : Representation_Legality_Info) return Boolean
     renames Editor.Ada_Representation_Legality.Interfacing_Checks.Has_Opposite_Enabled_Import_Export;

   procedure Finalize_Interfacing_Conflicts
     (Model : in out Representation_Legality_Model)
     renames Editor.Ada_Representation_Legality.Interfacing_Checks.Finalize_Interfacing_Conflicts;

   function Stream_Profile_Conforms
     (Kind    : Editor.Ada_Language_Model.Representation_Clause_Kind;
      Profile : Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info) return Boolean
     renames Editor.Ada_Representation_Legality.Stream_Profile_Checks.Stream_Profile_Conforms;

   function Unique_Visible_Declaration
     (Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Name       : String) return Editor.Ada_Direct_Visibility.Lookup_Result
     renames Editor.Ada_Representation_Legality.Stream_Profile_Checks.Unique_Visible_Declaration;





   procedure Classify
     (Info : in out Representation_Legality_Info;
      Kind : Editor.Ada_Language_Model.Representation_Clause_Kind) is
   begin
      if Info.Freeze_Status = Editor.Ada_Freezing_Points.Representation_Target_Unresolved then
         Info.Status := Representation_Legality_Target_Unresolved;
      elsif Info.Freeze_Status = Editor.Ada_Freezing_Points.Representation_Target_Ambiguous then
         Info.Status := Representation_Legality_Target_Ambiguous;
      elsif Info.Freeze_Status = Editor.Ada_Freezing_Points.Representation_Target_Not_Freezable then
         Info.Status := Representation_Legality_Target_Not_Freezable;
      elsif Operational_Clause (Kind)
        and then not Operational_Target_Compatible
          (Kind, Info.Target_Freezable_Kind, Info.Target_Category)
      then
         Info.Status := Representation_Legality_Operational_Target_Incompatible;
      elsif Boolean_Operational_Clause (Kind)
        and then Info.Operational_Status not in Operational_Value_Static_Boolean_True |
                                            Operational_Value_Static_Boolean_False
      then
         Info.Status := Representation_Legality_Operational_Boolean_Value_Required;
      elsif Order_Operational_Clause (Kind)
        and then Info.Operational_Status not in Operational_Value_Order_High_Order_First |
                                            Operational_Value_Order_Low_Order_First
      then
         Info.Status := Representation_Legality_Operational_Order_Value_Required;
      elsif Interfacing_Clause (Kind)
        and then not Interfacing_Target_Compatible (Kind, Info.Target_Freezable_Kind)
      then
         Info.Status := Representation_Legality_Interfacing_Target_Incompatible;
      elsif Kind = Editor.Ada_Language_Model.Representation_Convention_Clause
        and then Info.Interfacing_Status = Interfacing_Value_Malformed
      then
         Info.Status := Representation_Legality_Convention_Identifier_Required;
      elsif Kind = Editor.Ada_Language_Model.Representation_Convention_Clause
        and then Info.Interfacing_Status = Interfacing_Value_Convention_Unknown_Identifier
      then
         Info.Status := Representation_Legality_Convention_Identifier_Unknown;
      elsif Kind in Editor.Ada_Language_Model.Representation_Import_Clause |
                    Editor.Ada_Language_Model.Representation_Export_Clause
        and then Info.Interfacing_Status = Interfacing_Value_Malformed
      then
         Info.Status := Representation_Legality_Import_Export_Boolean_Value_Required;
      elsif Kind in Editor.Ada_Language_Model.Representation_External_Name_Clause |
                    Editor.Ada_Language_Model.Representation_Link_Name_Clause
        and then Info.Interfacing_Status = Interfacing_Value_Malformed
      then
         Info.Status := Representation_Legality_Link_Name_String_Value_Required;
      elsif Stream_Attribute_Clause (Kind)
        and then not Stream_Target_Compatible (Info.Target_Freezable_Kind)
      then
         if Info.Stream_Status = Stream_Subprogram_Profile_Unknown then
            Info.Stream_Status := Stream_Subprogram_Designator;
         end if;
         Info.Status := Representation_Legality_Stream_Target_Incompatible;
      elsif Stream_Attribute_Clause (Kind)
        and then Info.Stream_Status in Stream_Subprogram_Malformed |
                                   Stream_Subprogram_Unknown
      then
         Info.Status := Representation_Legality_Stream_Subprogram_Malformed;
      elsif Stream_Attribute_Clause (Kind)
        and then Info.Stream_Status = Stream_Subprogram_Profile_Unknown
      then
         Info.Status := Representation_Legality_Stream_Subprogram_Profile_Unknown;
      elsif Stream_Attribute_Clause (Kind)
        and then Info.Stream_Status = Stream_Subprogram_Profile_Known_Mismatch
      then
         Info.Status := Representation_Legality_Stream_Subprogram_Profile_Mismatch;
      elsif Kind = Editor.Ada_Language_Model.Representation_Address_Clause
        and then not Compatible_Address_Target (Info.Target_Freezable_Kind)
      then
         Info.Status := Representation_Legality_Address_Target_Incompatible;
      elsif Kind = Editor.Ada_Language_Model.Representation_Address_Clause
        and then Info.Address_Status = Address_Value_Null_Literal
      then
         Info.Status := Representation_Legality_Address_Value_Null_Not_Allowed;
      elsif Kind = Editor.Ada_Language_Model.Representation_Address_Clause
        and then Info.Address_Status in Address_Value_Non_Static_Name |
                                        Address_Value_Unknown
      then
         Info.Status := Representation_Legality_Address_Value_Not_Static_Address;
      elsif Kind = Editor.Ada_Language_Model.Representation_Address_Clause
        and then Info.Address_Status = Address_Value_Raw_Literal
      then
         Info.Status := Representation_Legality_Address_Value_Incompatible;
      elsif Kind = Editor.Ada_Language_Model.Representation_Address_Clause
        and then Info.Address_Status = Address_Value_Malformed
      then
         Info.Status := Representation_Legality_Address_Value_Malformed;
      elsif Kind in Editor.Ada_Language_Model.Representation_Size_Clause |
                    Editor.Ada_Language_Model.Representation_Object_Size_Clause |
                    Editor.Ada_Language_Model.Representation_Value_Size_Clause
        and then not Size_Target_Compatible (Info.Target_Freezable_Kind)
      then
         Info.Status := Representation_Legality_Size_Target_Incompatible;
      elsif Kind = Editor.Ada_Language_Model.Representation_Alignment_Clause
        and then not Alignment_Target_Compatible (Info.Target_Freezable_Kind)
      then
         Info.Status := Representation_Legality_Alignment_Target_Incompatible;
      elsif Kind = Editor.Ada_Language_Model.Representation_Storage_Size_Clause
        and then not Storage_Size_Target_Compatible
          (Info.Target_Freezable_Kind, Info.Target_Category)
      then
         Info.Status := Representation_Legality_Storage_Size_Target_Incompatible;
      elsif not Compatible_Target_Kind (Kind, Info.Target_Category) then
         Info.Status := Representation_Legality_Target_Kind_Mismatch;
      elsif Info.Freeze_Status = Editor.Ada_Freezing_Points.Representation_After_Freezing then
         Info.Status := Representation_Legality_After_Freezing;
      elsif Info.Freeze_Status = Editor.Ada_Freezing_Points.Representation_At_Freezing_Point then
         Info.Status := Representation_Legality_At_Freezing_Point;
      elsif Static_Value_Required (Kind)
        and then Info.Value_Status not in Representation_Value_Static_Integer |
                                      Representation_Value_Static_Real
      then
         case Info.Value_Status is
            when Representation_Value_Malformed =>
               Info.Status := Representation_Legality_Static_Value_Malformed;
            when Representation_Value_Division_By_Zero =>
               Info.Status := Representation_Legality_Static_Value_Division_By_Zero;
            when others =>
               Info.Status := Representation_Legality_Static_Value_Required;
         end case;
      elsif Integer_Value_Required (Kind)
        and then Info.Value_Status = Representation_Value_Static_Real
      then
         Info.Status := Representation_Legality_Static_Value_Not_Integer;
      elsif Positive_Value_Required (Kind)
        and then Info.Value_Status = Representation_Value_Static_Integer
        and then Info.Static_Integer <= 0
      then
         Info.Status := Representation_Legality_Static_Value_Not_Positive;
      else
         Info.Status := Representation_Legality_Ok;
      end if;
   end Classify;

   procedure Clear (Model : in out Representation_Legality_Model) is
   begin
      Model.Checks.Clear;
      Model.Component_Checks.Clear;
      Model.Enumeration_Checks.Clear;
      Model.Ok_Total := 0;
      Model.Error_Total := 0;
      Model.Static_Error_Total := 0;
      Model.Kind_Error_Total := 0;
      Model.Freeze_Error_Total := 0;
      Model.Component_Error_Total := 0;
      Model.Component_Duplicate_Total := 0;
      Model.Component_Static_Error_Total := 0;
      Model.Enumeration_Error_Total := 0;
      Model.Enumeration_Duplicate_Literal_Total := 0;
      Model.Enumeration_Duplicate_Value_Total := 0;
      Model.Enumeration_Static_Error_Total := 0;
      Model.Enumeration_Incomplete_Total := 0;
      Model.Address_Target_Error_Total := 0;
      Model.Address_Value_Error_Total := 0;
      Model.Address_Static_Value_Total := 0;
      Model.Size_Alignment_Storage_Error_Total := 0;
      Model.Size_Alignment_Storage_Static_Error_Total := 0;
      Model.Interfacing_Error_Total := 0;
      Model.Interfacing_Target_Error_Total := 0;
      Model.Interfacing_Value_Error_Total := 0;
      Model.Import_Export_Conflict_Total := 0;
      Model.Link_Name_Requires_Import_Export_Total := 0;
      Model.Stream_Error_Total := 0;
      Model.Stream_Target_Error_Total := 0;
      Model.Stream_Profile_Error_Total := 0;
      Model.Stream_Profile_Unknown_Total := 0;
      Model.Operational_Error_Total := 0;
      Model.Operational_Target_Error_Total := 0;
      Model.Operational_Value_Error_Total := 0;
      Model.Operational_Static_Boolean_Total := 0;
      Model.Operational_Order_Value_Total := 0;
      Model.Aspect_Source_Total := 0;
      Model.Attribute_Definition_Source_Total := 0;
      Model.Unified_Property_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;























   procedure Recount (Model : in out Representation_Legality_Model) is
   begin
      Model.Ok_Total := 0;
      Model.Error_Total := 0;
      Model.Static_Error_Total := 0;
      Model.Kind_Error_Total := 0;
      Model.Freeze_Error_Total := 0;
      Model.Component_Error_Total := 0;
      Model.Component_Duplicate_Total := 0;
      Model.Component_Static_Error_Total := 0;
      Model.Enumeration_Error_Total := 0;
      Model.Enumeration_Duplicate_Literal_Total := 0;
      Model.Enumeration_Duplicate_Value_Total := 0;
      Model.Enumeration_Static_Error_Total := 0;
      Model.Enumeration_Incomplete_Total := 0;
      Model.Address_Target_Error_Total := 0;
      Model.Address_Value_Error_Total := 0;
      Model.Address_Static_Value_Total := 0;
      Model.Size_Alignment_Storage_Error_Total := 0;
      Model.Size_Alignment_Storage_Static_Error_Total := 0;
      Model.Interfacing_Error_Total := 0;
      Model.Interfacing_Target_Error_Total := 0;
      Model.Interfacing_Value_Error_Total := 0;
      Model.Import_Export_Conflict_Total := 0;
      Model.Link_Name_Requires_Import_Export_Total := 0;
      Model.Stream_Error_Total := 0;
      Model.Stream_Target_Error_Total := 0;
      Model.Stream_Profile_Error_Total := 0;
      Model.Stream_Profile_Unknown_Total := 0;
      Model.Operational_Error_Total := 0;
      Model.Operational_Target_Error_Total := 0;
      Model.Operational_Value_Error_Total := 0;
      Model.Operational_Static_Boolean_Total := 0;
      Model.Operational_Order_Value_Total := 0;
      Model.Aspect_Source_Total := 0;
      Model.Attribute_Definition_Source_Total := 0;
      Model.Unified_Property_Total := 0;
      Model.Result_Fingerprint := 0;

      for Index in 1 .. Natural (Model.Checks.Length) loop
         declare
            Info : constant Representation_Legality_Info := Model.Checks (Index);
         begin
            Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
            if Info.Source_Form = Editor.Ada_Language_Model.Representation_Source_Aspect then
               Model.Aspect_Source_Total := Model.Aspect_Source_Total + 1;
               Model.Unified_Property_Total := Model.Unified_Property_Total + 1;
            elsif Info.Source_Form =
              Editor.Ada_Language_Model.Representation_Source_Attribute_Definition
            then
               Model.Attribute_Definition_Source_Total :=
                 Model.Attribute_Definition_Source_Total + 1;
               Model.Unified_Property_Total := Model.Unified_Property_Total + 1;
            end if;
            if Info.Status = Representation_Legality_Ok then
               Model.Ok_Total := Model.Ok_Total + 1;
            else
               Model.Error_Total := Model.Error_Total + 1;
            end if;

            if Info.Status in Representation_Legality_Static_Value_Required |
                              Representation_Legality_Static_Value_Malformed |
                              Representation_Legality_Static_Value_Division_By_Zero |
                              Representation_Legality_Static_Value_Not_Positive |
                              Representation_Legality_Static_Value_Not_Integer
            then
               Model.Static_Error_Total := Model.Static_Error_Total + 1;
            end if;

            if Info.Status in Representation_Legality_Target_Kind_Mismatch |
                              Representation_Legality_Size_Target_Incompatible |
                              Representation_Legality_Alignment_Target_Incompatible |
                              Representation_Legality_Storage_Size_Target_Incompatible
            then
               Model.Kind_Error_Total := Model.Kind_Error_Total + 1;
            end if;

            if Info.Status in Representation_Legality_Size_Target_Incompatible |
                              Representation_Legality_Alignment_Target_Incompatible |
                              Representation_Legality_Storage_Size_Target_Incompatible
            then
               Model.Size_Alignment_Storage_Error_Total :=
                 Model.Size_Alignment_Storage_Error_Total + 1;
            end if;

            if Info.Status in Representation_Legality_Static_Value_Required |
                              Representation_Legality_Static_Value_Malformed |
                              Representation_Legality_Static_Value_Division_By_Zero |
                              Representation_Legality_Static_Value_Not_Positive |
                              Representation_Legality_Static_Value_Not_Integer
              and then Info.Clause_Kind in Editor.Ada_Language_Model.Representation_Size_Clause |
                                           Editor.Ada_Language_Model.Representation_Alignment_Clause |
                                           Editor.Ada_Language_Model.Representation_Component_Size_Clause |
                                           Editor.Ada_Language_Model.Representation_Object_Size_Clause |
                                           Editor.Ada_Language_Model.Representation_Value_Size_Clause |
                                           Editor.Ada_Language_Model.Representation_Storage_Size_Clause |
                                           Editor.Ada_Language_Model.Representation_Machine_Radix_Clause |
                                           Editor.Ada_Language_Model.Representation_Aft_Clause
            then
               Model.Size_Alignment_Storage_Static_Error_Total :=
                 Model.Size_Alignment_Storage_Static_Error_Total + 1;
            end if;

            if Info.Status in Representation_Legality_After_Freezing |
                              Representation_Legality_At_Freezing_Point
            then
               Model.Freeze_Error_Total := Model.Freeze_Error_Total + 1;
            end if;

            if Info.Status = Representation_Legality_Address_Target_Incompatible then
               Model.Address_Target_Error_Total := Model.Address_Target_Error_Total + 1;
            elsif Info.Status in Representation_Legality_Address_Value_Null_Not_Allowed |
                                 Representation_Legality_Address_Value_Not_Static_Address |
                                 Representation_Legality_Address_Value_Incompatible |
                                 Representation_Legality_Address_Value_Malformed
            then
               Model.Address_Value_Error_Total := Model.Address_Value_Error_Total + 1;
            end if;
            if Info.Address_Status = Address_Value_Static_Address then
               Model.Address_Static_Value_Total := Model.Address_Static_Value_Total + 1;
            end if;

            if Info.Status in Representation_Legality_Interfacing_Target_Incompatible |
                              Representation_Legality_Convention_Identifier_Required |
                              Representation_Legality_Convention_Identifier_Unknown |
                              Representation_Legality_Import_Export_Boolean_Value_Required |
                              Representation_Legality_Link_Name_String_Value_Required |
                              Representation_Legality_Import_Export_Conflict |
                              Representation_Legality_Link_Name_Requires_Import_Export
            then
               Model.Interfacing_Error_Total := Model.Interfacing_Error_Total + 1;
            end if;
            if Info.Status = Representation_Legality_Interfacing_Target_Incompatible then
               Model.Interfacing_Target_Error_Total := Model.Interfacing_Target_Error_Total + 1;
            elsif Info.Status in Representation_Legality_Convention_Identifier_Required |
                                 Representation_Legality_Convention_Identifier_Unknown |
                                 Representation_Legality_Import_Export_Boolean_Value_Required |
                                 Representation_Legality_Link_Name_String_Value_Required
            then
               Model.Interfacing_Value_Error_Total := Model.Interfacing_Value_Error_Total + 1;
            elsif Info.Status = Representation_Legality_Import_Export_Conflict then
               Model.Import_Export_Conflict_Total := Model.Import_Export_Conflict_Total + 1;
            elsif Info.Status = Representation_Legality_Link_Name_Requires_Import_Export then
               Model.Link_Name_Requires_Import_Export_Total :=
                 Model.Link_Name_Requires_Import_Export_Total + 1;
            end if;

            if Info.Status in Representation_Legality_Operational_Target_Incompatible |
                              Representation_Legality_Operational_Boolean_Value_Required |
                              Representation_Legality_Operational_Order_Value_Required
            then
               Model.Operational_Error_Total := Model.Operational_Error_Total + 1;
            end if;
            if Info.Status = Representation_Legality_Operational_Target_Incompatible then
               Model.Operational_Target_Error_Total := Model.Operational_Target_Error_Total + 1;
            elsif Info.Status in Representation_Legality_Operational_Boolean_Value_Required |
                                 Representation_Legality_Operational_Order_Value_Required
            then
               Model.Operational_Value_Error_Total := Model.Operational_Value_Error_Total + 1;
            end if;
            if Info.Operational_Status in Operational_Value_Static_Boolean_True |
                                          Operational_Value_Static_Boolean_False
            then
               Model.Operational_Static_Boolean_Total :=
                 Model.Operational_Static_Boolean_Total + 1;
            elsif Info.Operational_Status in Operational_Value_Order_High_Order_First |
                                       Operational_Value_Order_Low_Order_First
            then
               Model.Operational_Order_Value_Total :=
                 Model.Operational_Order_Value_Total + 1;
            end if;

            if Info.Status in Representation_Legality_Stream_Target_Incompatible |
                              Representation_Legality_Stream_Subprogram_Required |
                              Representation_Legality_Stream_Subprogram_Malformed |
                              Representation_Legality_Stream_Subprogram_Profile_Unknown |
                              Representation_Legality_Stream_Subprogram_Profile_Mismatch
            then
               Model.Stream_Error_Total := Model.Stream_Error_Total + 1;
            end if;
            if Info.Status = Representation_Legality_Stream_Target_Incompatible then
               Model.Stream_Target_Error_Total := Model.Stream_Target_Error_Total + 1;
            elsif Info.Status = Representation_Legality_Stream_Subprogram_Profile_Mismatch then
               Model.Stream_Profile_Error_Total := Model.Stream_Profile_Error_Total + 1;
            elsif Info.Status = Representation_Legality_Stream_Subprogram_Profile_Unknown then
               Model.Stream_Profile_Unknown_Total := Model.Stream_Profile_Unknown_Total + 1;
            end if;
         end;
      end loop;

      for Index in 1 .. Natural (Model.Component_Checks.Length) loop
         Count_Component_Result (Model, Model.Component_Checks (Index));
      end loop;
      for Index in 1 .. Natural (Model.Enumeration_Checks.Length) loop
         Count_Enumeration_Result (Model, Model.Enumeration_Checks (Index));
      end loop;
   end Recount;

   function Build
     (Tree     : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions  : Editor.Ada_Declarative_Regions.Region_Model;
      Types    : Editor.Ada_Type_Graph.Type_Model;
      Static   : Editor.Ada_Static_Expressions.Static_Model;
      Freezing : Editor.Ada_Freezing_Points.Freezing_Model)
      return Representation_Legality_Model is
      Model : Representation_Legality_Model;
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node_At (Tree, Index);
         begin
            if Node.Kind = Editor.Ada_Syntax_Tree.Node_Representation_Clause then
               declare
                  Target_Text : constant String :=
                    Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Representation_Target);
                  Item_Text : constant String :=
                    Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Representation_Item);
                  Kind : constant Editor.Ada_Language_Model.Representation_Clause_Kind :=
                    Clause_Kind (Target_Text, Item_Text, To_String (Node.Label));
                  Freeze : constant Editor.Ada_Freezing_Points.Representation_Freeze_Info :=
                    Editor.Ada_Freezing_Points.Representation_Check_For_Clause (Freezing, Node.Id);
                  Info : Representation_Legality_Info;
               begin
                  Info.Clause_Node := Node.Id;
                  Info.Target_Name := To_Unbounded_String (Trimmed (Target_Text));
                  Info.Normalized_Target := To_Unbounded_String (Normalized (Target_Text));
                  Info.Clause_Kind := Kind;
                  Info.Source_Form :=
                    Editor.Ada_Language_Model.Representation_Source_Attribute_Definition;
                  Info.Item_Text := To_Unbounded_String (Trimmed (Item_Text));
                  Info.Target := Freeze.Target;
                  Info.Freeze_Status := Freeze.Status;
                  Info.Source_Line := Node.Source_Span.Start_Line;

                  if Info.Target /= Editor.Ada_Freezing_Points.No_Freezable then
                     declare
                        Target_Info : constant Editor.Ada_Freezing_Points.Freezable_Info :=
                          Editor.Ada_Freezing_Points.Freezable_Node (Freezing, Info.Target);
                     begin
                        Info.Target_Freezable_Kind := Target_Info.Kind;
                        Info.Target_Type := Target_Info.Type_Node;
                        Info.Target_Category := Type_Category_For_Target (Types, Target_Info);
                     end;
                  end if;

                  if Operational_Clause (Kind) then
                     Info.Operational_Status := Operational_Value_Status_For (Kind, Item_Text);
                     Info.Value_Status := Representation_Value_Not_Required;
                  elsif Interfacing_Clause (Kind) then
                     Info.Interfacing_Status := Interfacing_Value_Status_For (Kind, Item_Text);
                     if Kind = Editor.Ada_Language_Model.Representation_Convention_Clause then
                        Info.Convention_Name := To_Unbounded_String (Trimmed (Item_Text));
                     end if;
                     Info.Value_Status := Representation_Value_Not_Required;
                  elsif Stream_Attribute_Clause (Kind) then
                     Info.Stream_Status := Stream_Subprogram_Status_For (Kind, Item_Text);
                     Info.Stream_Designator := To_Unbounded_String (Trimmed (Item_Text));
                     Info.Value_Status := Representation_Value_Not_Required;
                  elsif Kind = Editor.Ada_Language_Model.Representation_Address_Clause then
                     Info.Address_Status := Address_Value_Status_For (Item_Text);
                     Info.Value_Status := Representation_Value_Not_Required;
                  elsif Static_Value_Required (Kind) then
                     declare
                        Value : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
                          Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression
                            (Static, Editor.Ada_Declarative_Regions.No_Region, Item_Text);
                     begin
                        Info.Value_Status := Value_Status_For (Value);
                        Info.Static_Integer := Value.Integer_Value;
                        Info.Static_Real := Value.Real_Value;
                     end;
                  else
                     Info.Value_Status := Representation_Value_Not_Required;
                  end if;

                  Classify (Info, Kind);
                  Info.Fingerprint := Mix (Natural (Info.Clause_Node), Natural (Info.Target));
                  Info.Fingerprint := Mix (Info.Fingerprint, Natural (Info.Target_Type));
                  Info.Fingerprint := Mix (Info.Fingerprint, Info.Source_Line);
                  Info.Fingerprint := Mix (Info.Fingerprint, Representation_Legality_Status'Pos (Info.Status));
                  Info.Fingerprint := Mix (Info.Fingerprint, Representation_Value_Status'Pos (Info.Value_Status));
                  Info.Fingerprint := Mix (Info.Fingerprint, Address_Value_Status'Pos (Info.Address_Status));
                  Info.Fingerprint := Mix (Info.Fingerprint, Interfacing_Value_Status'Pos (Info.Interfacing_Status));
                  Info.Fingerprint := Mix (Info.Fingerprint, Stream_Subprogram_Status'Pos (Info.Stream_Status));
                  Info.Fingerprint := Mix (Info.Fingerprint, Operational_Value_Status'Pos (Info.Operational_Status));

                  Model.Checks.Append (Info);
                  Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);

                  if Info.Status = Representation_Legality_Ok then
                     Model.Ok_Total := Model.Ok_Total + 1;
                  else
                     Model.Error_Total := Model.Error_Total + 1;
                     if Info.Status in Representation_Legality_Static_Value_Required |
                                       Representation_Legality_Static_Value_Malformed |
                                       Representation_Legality_Static_Value_Division_By_Zero |
                                       Representation_Legality_Static_Value_Not_Positive |
                                       Representation_Legality_Static_Value_Not_Integer
                     then
                        Model.Static_Error_Total := Model.Static_Error_Total + 1;
                        if Kind in Editor.Ada_Language_Model.Representation_Size_Clause |
                                   Editor.Ada_Language_Model.Representation_Alignment_Clause |
                                   Editor.Ada_Language_Model.Representation_Component_Size_Clause |
                                   Editor.Ada_Language_Model.Representation_Object_Size_Clause |
                                   Editor.Ada_Language_Model.Representation_Value_Size_Clause |
                                   Editor.Ada_Language_Model.Representation_Storage_Size_Clause |
                                   Editor.Ada_Language_Model.Representation_Machine_Radix_Clause |
                                   Editor.Ada_Language_Model.Representation_Aft_Clause
                        then
                           Model.Size_Alignment_Storage_Static_Error_Total :=
                             Model.Size_Alignment_Storage_Static_Error_Total + 1;
                        end if;
                     elsif Info.Status in Representation_Legality_Size_Target_Incompatible |
                                        Representation_Legality_Alignment_Target_Incompatible |
                                        Representation_Legality_Storage_Size_Target_Incompatible
                     then
                        Model.Kind_Error_Total := Model.Kind_Error_Total + 1;
                        Model.Size_Alignment_Storage_Error_Total :=
                          Model.Size_Alignment_Storage_Error_Total + 1;
                     elsif Info.Status = Representation_Legality_Target_Kind_Mismatch then
                        Model.Kind_Error_Total := Model.Kind_Error_Total + 1;
                     elsif Info.Status = Representation_Legality_Address_Target_Incompatible then
                        Model.Address_Target_Error_Total := Model.Address_Target_Error_Total + 1;
                     elsif Info.Status in Representation_Legality_Address_Value_Null_Not_Allowed |
                                        Representation_Legality_Address_Value_Not_Static_Address |
                                        Representation_Legality_Address_Value_Incompatible |
                                        Representation_Legality_Address_Value_Malformed
                     then
                        Model.Address_Value_Error_Total := Model.Address_Value_Error_Total + 1;
                     elsif Info.Status in Representation_Legality_After_Freezing |
                                        Representation_Legality_At_Freezing_Point
                     then
                        Model.Freeze_Error_Total := Model.Freeze_Error_Total + 1;
                     end if;

                  end if;

                  if Info.Address_Status = Address_Value_Static_Address then
                     Model.Address_Static_Value_Total := Model.Address_Static_Value_Total + 1;
                  end if;

                  if Kind = Editor.Ada_Language_Model.Representation_Enumeration_Clause then
                     Add_Enumeration_Representation_Checks
                       (Model, Tree, Types, Static, Node, Info);
                  end if;
               end;
            elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Aspect_Association then
               declare
                  Label_Text : constant String := To_String (Node.Label);
                  Arrow : constant Natural := Ada.Strings.Fixed.Index (Label_Text, "=>");
                  Named_Aspect : constant String :=
                    Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Aspect_Name);
                  Value_Child : constant String :=
                    Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Aspect_Value);
                  Aspect_Name : constant String :=
                    (if Named_Aspect /= "" then Trimmed (Named_Aspect)
                     elsif Arrow /= 0 then Trimmed (Label_Text (Label_Text'First .. Arrow - 1))
                     else Trimmed (Label_Text));
                  Raw_Value : constant String :=
                    (if Value_Child /= "" then Trimmed (Value_Child)
                     elsif Arrow /= 0 and then Arrow + 2 <= Label_Text'Last then
                        Trimmed (Label_Text (Arrow + 2 .. Label_Text'Last))
                     else "");
                  Item_Text : constant String := Aspect_Default_Value (Aspect_Name, Raw_Value);
                  Target_Text : constant String := Ancestor_Declaration_Target (Tree, Node.Id);
               begin
                  if Target_Text /= "" and then Aspect_Representation_Name (Aspect_Name) then
                     declare
                        Synthetic_Target : constant String :=
                          Target_Text & Character'Val (39) & Aspect_Name;
                        Kind : constant Editor.Ada_Language_Model.Representation_Clause_Kind :=
                          Clause_Kind (Synthetic_Target, Item_Text, Synthetic_Target & " use " & Item_Text);
                        Freeze : constant Editor.Ada_Freezing_Points.Representation_Freeze_Info :=
                          Freeze_Info_For_Target_At
                            (Freezing, Regions, Node.Source_Span.Start_Line, Target_Text);
                        Info : Representation_Legality_Info;
                     begin
                        Info.Clause_Node := Node.Id;
                        Info.Target_Name := To_Unbounded_String (Trimmed (Target_Text));
                        Info.Normalized_Target := To_Unbounded_String (Normalized (Target_Text));
                        Info.Clause_Kind := Kind;
                        Info.Source_Form := Editor.Ada_Language_Model.Representation_Source_Aspect;
                        Info.Item_Text := To_Unbounded_String (Trimmed (Item_Text));
                        Info.Target := Freeze.Target;
                        Info.Freeze_Status := Freeze.Status;
                        Info.Source_Line := Node.Source_Span.Start_Line;

                        if Info.Target /= Editor.Ada_Freezing_Points.No_Freezable then
                           declare
                              Target_Info : constant Editor.Ada_Freezing_Points.Freezable_Info :=
                                Editor.Ada_Freezing_Points.Freezable_Node (Freezing, Info.Target);
                           begin
                              Info.Target_Freezable_Kind := Target_Info.Kind;
                              Info.Target_Type := Target_Info.Type_Node;
                              Info.Target_Category := Type_Category_For_Target (Types, Target_Info);
                           end;
                        end if;

                        if Operational_Clause (Kind) then
                           Info.Operational_Status := Operational_Value_Status_For (Kind, Item_Text);
                           Info.Value_Status := Representation_Value_Not_Required;
                        elsif Interfacing_Clause (Kind) then
                           Info.Interfacing_Status := Interfacing_Value_Status_For (Kind, Item_Text);
                           if Kind = Editor.Ada_Language_Model.Representation_Convention_Clause then
                              Info.Convention_Name := To_Unbounded_String (Trimmed (Item_Text));
                           end if;
                           Info.Value_Status := Representation_Value_Not_Required;
                        elsif Stream_Attribute_Clause (Kind) then
                           Info.Stream_Status := Stream_Subprogram_Status_For (Kind, Item_Text);
                           Info.Stream_Designator := To_Unbounded_String (Trimmed (Item_Text));
                           Info.Value_Status := Representation_Value_Not_Required;
                        elsif Kind = Editor.Ada_Language_Model.Representation_Address_Clause then
                           Info.Address_Status := Address_Value_Status_For (Item_Text);
                           Info.Value_Status := Representation_Value_Not_Required;
                        elsif Static_Value_Required (Kind) then
                           declare
                              Value : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
                                Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression
                                  (Static, Editor.Ada_Declarative_Regions.No_Region, Item_Text);
                           begin
                              Info.Value_Status := Value_Status_For (Value);
                              Info.Static_Integer := Value.Integer_Value;
                              Info.Static_Real := Value.Real_Value;
                           end;
                        else
                           Info.Value_Status := Representation_Value_Not_Required;
                        end if;

                        Classify (Info, Kind);
                        Info.Fingerprint := Mix (Natural (Info.Clause_Node), Natural (Info.Target));
                        Info.Fingerprint := Mix (Info.Fingerprint, Natural (Info.Target_Type));
                        Info.Fingerprint := Mix (Info.Fingerprint, Info.Source_Line);
                        Info.Fingerprint := Mix (Info.Fingerprint, Representation_Legality_Status'Pos (Info.Status));
                        Info.Fingerprint := Mix (Info.Fingerprint, Representation_Value_Status'Pos (Info.Value_Status));
                        Info.Fingerprint := Mix (Info.Fingerprint, Address_Value_Status'Pos (Info.Address_Status));
                        Info.Fingerprint := Mix (Info.Fingerprint, Interfacing_Value_Status'Pos (Info.Interfacing_Status));
                        Info.Fingerprint := Mix (Info.Fingerprint, Stream_Subprogram_Status'Pos (Info.Stream_Status));
                        Info.Fingerprint := Mix (Info.Fingerprint, Operational_Value_Status'Pos (Info.Operational_Status));

                        Model.Checks.Append (Info);
                        Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);
                     end;
                  end if;
               end;
            elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Representation_Component_Clause then
               Add_Record_Component_Check (Model, Tree, Types, Static, Node);
            end if;
         end;
      end loop;

      Finalize_Interfacing_Conflicts (Model);
      Recount (Model);
      return Model;
   end Build;





   procedure Apply_Stream_Profile_Resolution
     (Model      : in out Representation_Legality_Model;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Profiles   : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model) is
      use type Editor.Ada_Direct_Visibility.Lookup_Status;
      use type Editor.Ada_Direct_Visibility.Declaration_Kind;
      use type Editor.Ada_Call_Profile_Shapes.Callable_Profile_Status;
   begin
      for Index in 1 .. Natural (Model.Checks.Length) loop
         declare
            Info : Representation_Legality_Info := Model.Checks (Index);
         begin
            if Stream_Attribute_Clause (Info.Clause_Kind)
              and then Info.Stream_Status = Stream_Subprogram_Profile_Unknown
            then
               declare
                  Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
                    Deepest_Region_Containing_Line (Regions, Info.Source_Line);
                  Lookup : Editor.Ada_Direct_Visibility.Lookup_Result :=
                    Editor.Ada_Direct_Visibility.Lookup_Visible
                      (Visibility, Regions, Region, To_String (Info.Stream_Designator));
               begin
                  if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Not_Found then
                     Lookup := Unique_Visible_Declaration
                       (Visibility, To_String (Info.Stream_Designator));
                  end if;

                  if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
                     declare
                        Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                          Editor.Ada_Direct_Visibility.Declaration
                            (Visibility, Lookup.Declaration);
                        Profile : constant Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info :=
                          Editor.Ada_Call_Profile_Shapes.Callable_Profile_For_Node
                            (Profiles, Decl.Node);
                     begin
                        if Decl.Kind = Editor.Ada_Direct_Visibility.Declaration_Subprogram
                          and then Stream_Profile_Conforms (Info.Clause_Kind, Profile)
                        then
                           Info.Stream_Status := Stream_Subprogram_Profile_Known_Compatible;
                           Info.Status := Representation_Legality_Ok;
                        elsif Decl.Kind = Editor.Ada_Direct_Visibility.Declaration_Subprogram
                          and then Profile.Status = Editor.Ada_Call_Profile_Shapes.Callable_Profile_Found
                        then
                           Info.Stream_Status := Stream_Subprogram_Profile_Known_Mismatch;
                           Info.Status := Representation_Legality_Stream_Subprogram_Profile_Mismatch;
                        else
                           Info.Stream_Status := Stream_Subprogram_Profile_Unknown;
                           Info.Status := Representation_Legality_Stream_Subprogram_Profile_Unknown;
                        end if;
                     end;
                  else
                     Info.Stream_Status := Stream_Subprogram_Profile_Unknown;
                     Info.Status := Representation_Legality_Stream_Subprogram_Profile_Unknown;
                  end if;
               end;

               Info.Fingerprint :=
                 Mix (Natural (Info.Clause_Node),
                      Mix (Info.Source_Line,
                           Mix (Representation_Legality_Status'Pos (Info.Status),
                                Stream_Subprogram_Status'Pos (Info.Stream_Status))));
               Model.Checks.Replace_Element (Index, Info);
            end if;
         end;
      end loop;
      Recount (Model);
   end Apply_Stream_Profile_Resolution;

   function Build_With_Stream_Profiles
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Freezing   : Editor.Ada_Freezing_Points.Freezing_Model;
      Profiles   : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model)
      return Representation_Legality_Model is
      Model : Representation_Legality_Model :=
        Build (Tree, Regions, Types, Static, Freezing);
   begin
      Apply_Stream_Profile_Resolution (Model, Regions, Visibility, Profiles);
      return Model;
   end Build_With_Stream_Profiles;

   function Check_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Natural (Model.Checks.Length);
   end Check_Count;

   function Check_At
     (Model : Representation_Legality_Model;
      Index : Positive) return Representation_Legality_Info is
   begin
      return Model.Checks (Index);
   end Check_At;

   function Check_For_Clause
     (Model  : Representation_Legality_Model;
      Clause : Editor.Ada_Syntax_Tree.Node_Id) return Representation_Legality_Info is
   begin
      for Index in 1 .. Natural (Model.Checks.Length) loop
         if Model.Checks (Index).Clause_Node = Clause then
            return Model.Checks (Index);
         end if;
      end loop;
      return (others => <>);
   end Check_For_Clause;

   function Record_Component_Check_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Natural (Model.Component_Checks.Length);
   end Record_Component_Check_Count;

   function Record_Component_Check_At
     (Model : Representation_Legality_Model;
      Index : Positive) return Record_Component_Legality_Info is
   begin
      return Model.Component_Checks (Index);
   end Record_Component_Check_At;

   function Ok_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Ok_Total;
   end Ok_Count;

   function Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Static_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Static_Error_Total;
   end Static_Error_Count;

   function Target_Kind_Mismatch_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Kind_Error_Total;
   end Target_Kind_Mismatch_Count;

   function After_Freezing_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Freeze_Error_Total;
   end After_Freezing_Count;

   function Record_Component_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Component_Error_Total;
   end Record_Component_Error_Count;

   function Record_Component_Duplicate_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Component_Duplicate_Total;
   end Record_Component_Duplicate_Count;

   function Record_Component_Static_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Component_Static_Error_Total;
   end Record_Component_Static_Error_Count;


   function Enumeration_Representation_Check_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Natural (Model.Enumeration_Checks.Length);
   end Enumeration_Representation_Check_Count;

   function Enumeration_Representation_Check_At
     (Model : Representation_Legality_Model;
      Index : Positive) return Enumeration_Representation_Legality_Info is
   begin
      return Model.Enumeration_Checks (Index);
   end Enumeration_Representation_Check_At;

   function Enumeration_Representation_Error_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Enumeration_Error_Total;
   end Enumeration_Representation_Error_Count;

   function Enumeration_Representation_Duplicate_Literal_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Enumeration_Duplicate_Literal_Total;
   end Enumeration_Representation_Duplicate_Literal_Count;

   function Enumeration_Representation_Duplicate_Value_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Enumeration_Duplicate_Value_Total;
   end Enumeration_Representation_Duplicate_Value_Count;

   function Enumeration_Representation_Static_Error_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Enumeration_Static_Error_Total;
   end Enumeration_Representation_Static_Error_Count;

   function Enumeration_Representation_Incomplete_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Enumeration_Incomplete_Total;
   end Enumeration_Representation_Incomplete_Count;


   function Address_Target_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Address_Target_Error_Total;
   end Address_Target_Error_Count;

   function Address_Value_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Address_Value_Error_Total;
   end Address_Value_Error_Count;

   function Address_Static_Value_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Address_Static_Value_Total;
   end Address_Static_Value_Count;

   function Size_Alignment_Storage_Error_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Size_Alignment_Storage_Error_Total;
   end Size_Alignment_Storage_Error_Count;

   function Size_Alignment_Storage_Static_Error_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Size_Alignment_Storage_Static_Error_Total;
   end Size_Alignment_Storage_Static_Error_Count;

   function Interfacing_Error_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Interfacing_Error_Total;
   end Interfacing_Error_Count;

   function Interfacing_Target_Error_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Interfacing_Target_Error_Total;
   end Interfacing_Target_Error_Count;

   function Interfacing_Value_Error_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Interfacing_Value_Error_Total;
   end Interfacing_Value_Error_Count;

   function Import_Export_Conflict_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Import_Export_Conflict_Total;
   end Import_Export_Conflict_Count;

   function Link_Name_Requires_Import_Export_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Link_Name_Requires_Import_Export_Total;
   end Link_Name_Requires_Import_Export_Count;


   function Stream_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Stream_Error_Total;
   end Stream_Error_Count;

   function Stream_Target_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Stream_Target_Error_Total;
   end Stream_Target_Error_Count;

   function Stream_Profile_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Stream_Profile_Error_Total;
   end Stream_Profile_Error_Count;

   function Stream_Profile_Unknown_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Stream_Profile_Unknown_Total;
   end Stream_Profile_Unknown_Count;

   function Operational_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Operational_Error_Total;
   end Operational_Error_Count;

   function Operational_Target_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Operational_Target_Error_Total;
   end Operational_Target_Error_Count;

   function Operational_Value_Error_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Operational_Value_Error_Total;
   end Operational_Value_Error_Count;

   function Operational_Static_Boolean_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Operational_Static_Boolean_Total;
   end Operational_Static_Boolean_Count;

   function Operational_Order_Value_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Operational_Order_Value_Total;
   end Operational_Order_Value_Count;

   function Aspect_Source_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Aspect_Source_Total;
   end Aspect_Source_Count;

   function Attribute_Definition_Source_Count
     (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Attribute_Definition_Source_Total;
   end Attribute_Definition_Source_Count;

   function Unified_Property_Count (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Unified_Property_Total;
   end Unified_Property_Count;

   function Fingerprint (Model : Representation_Legality_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Representation_Legality;
