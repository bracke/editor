with Editor.Ada_Language_Model;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Representation_Legality;
with Editor.Ada_Selected_Representation_Targets;
with Editor.Ada_Stream_Attribute_Profile_Conformance;
with Editor.Ada_Record_Layout_Exact_Validation;
with Editor.Ada_Record_Layout_Validation;
with Editor.Ada_Record_Storage_Order_Rules;
with Editor.Ada_Operational_Attribute_Rules;
with Editor.Ada_Aspect_Inheritance_Rules;
with Editor.Ada_Freezing_Interactions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Freezing_Points;

package body Editor.Ada_Representation_Diagnostics is

   pragma Suppress (Overflow_Check);

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        (Hash_Value (Left) * 16_777_619) xor
        (Hash_Value (Right) + 536_870_909);
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Kind_Code (Kind : Representation_Diagnostic_Kind) return Natural is
   begin
      return Representation_Diagnostic_Kind'Pos (Kind) + 1;
   end Kind_Code;

   function Severity_Code (Severity : Representation_Diagnostic_Severity) return Natural is
   begin
      return Representation_Diagnostic_Severity'Pos (Severity) + 1;
   end Severity_Code;

   function Make_Fingerprint
     (Kind : Representation_Diagnostic_Kind;
      Severity : Representation_Diagnostic_Severity;
      Seed : Natural) return Natural
   is
   begin
      return Mix (Mix (Kind_Code (Kind), Severity_Code (Severity)), Seed);
   end Make_Fingerprint;

   procedure Add
     (Model : in out Representation_Diagnostic_Model;
      Kind : Representation_Diagnostic_Kind;
      Severity : Representation_Diagnostic_Severity;
      Node : Editor.Ada_Syntax_Tree.Node_Id;
      Related_Node : Editor.Ada_Syntax_Tree.Node_Id;
      Target_Name : Unbounded_String;
      Property_Name : Unbounded_String;
      Line : Positive;
      Message : String;
      Seed : Natural)
   is
      Info : Representation_Diagnostic_Info;
   begin
      Info.Id := Representation_Diagnostic_Id (Natural (Model.Diagnostics.Length) + 1);
      Info.Kind := Kind;
      Info.Severity := Severity;
      Info.Node := Node;
      Info.Related_Node := Related_Node;
      Info.Target_Name := Target_Name;
      Info.Property_Name := Property_Name;
      Info.Start_Line := Line;
      Info.End_Line := Line;
      Info.Message := To_Unbounded_String (Message);
      Info.Fingerprint := Make_Fingerprint (Kind, Severity, Seed);
      Model.Diagnostics.Append (Info);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint);

      case Severity is
         when Representation_Diagnostic_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Representation_Diagnostic_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Representation_Diagnostic_Severity_Info =>
            Model.Info_Total := Model.Info_Total + 1;
      end case;
   end Add;

   function Legality_Kind
     (Status : Editor.Ada_Representation_Legality.Representation_Legality_Status)
      return Representation_Diagnostic_Kind
   is
      use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
   begin
      case Status is
         when Editor.Ada_Representation_Legality.Representation_Legality_Target_Unresolved |
              Editor.Ada_Representation_Legality.Representation_Legality_Target_Ambiguous |
              Editor.Ada_Representation_Legality.Representation_Legality_Target_Not_Freezable =>
            return Representation_Diagnostic_Target_Unresolved;
         when Editor.Ada_Representation_Legality.Representation_Legality_After_Freezing |
              Editor.Ada_Representation_Legality.Representation_Legality_At_Freezing_Point =>
            return Representation_Diagnostic_Freeze_Order_Error;
         when Editor.Ada_Representation_Legality.Representation_Legality_Static_Value_Required |
              Editor.Ada_Representation_Legality.Representation_Legality_Static_Value_Malformed |
              Editor.Ada_Representation_Legality.Representation_Legality_Static_Value_Division_By_Zero |
              Editor.Ada_Representation_Legality.Representation_Legality_Static_Value_Not_Positive |
              Editor.Ada_Representation_Legality.Representation_Legality_Static_Value_Not_Integer =>
            return Representation_Diagnostic_Static_Value_Error;
         when Editor.Ada_Representation_Legality.Representation_Legality_Target_Kind_Mismatch =>
            return Representation_Diagnostic_Target_Kind_Mismatch;
         when Editor.Ada_Representation_Legality.Representation_Legality_Record_Component_Unresolved |
              Editor.Ada_Representation_Legality.Representation_Legality_Record_Component_Duplicate |
              Editor.Ada_Representation_Legality.Representation_Legality_Record_Component_Static_Value_Required |
              Editor.Ada_Representation_Legality.Representation_Legality_Record_Component_Bit_Range_Reversed |
              Editor.Ada_Representation_Legality.Representation_Legality_Record_Component_Negative_Position =>
            return Representation_Diagnostic_Record_Component_Error;
         when Editor.Ada_Representation_Legality.Representation_Legality_Enumeration_Target_Not_Enumeration |
              Editor.Ada_Representation_Legality.Representation_Legality_Enumeration_Literal_Unresolved |
              Editor.Ada_Representation_Legality.Representation_Legality_Enumeration_Literal_Duplicate |
              Editor.Ada_Representation_Legality.Representation_Legality_Enumeration_Value_Static_Required |
              Editor.Ada_Representation_Legality.Representation_Legality_Enumeration_Value_Duplicate |
              Editor.Ada_Representation_Legality.Representation_Legality_Enumeration_Value_Order |
              Editor.Ada_Representation_Legality.Representation_Legality_Enumeration_Incomplete =>
            return Representation_Diagnostic_Enumeration_Error;
         when Editor.Ada_Representation_Legality.Representation_Legality_Address_Target_Incompatible |
              Editor.Ada_Representation_Legality.Representation_Legality_Address_Value_Null_Not_Allowed |
              Editor.Ada_Representation_Legality.Representation_Legality_Address_Value_Not_Static_Address |
              Editor.Ada_Representation_Legality.Representation_Legality_Address_Value_Incompatible |
              Editor.Ada_Representation_Legality.Representation_Legality_Address_Value_Malformed =>
            return Representation_Diagnostic_Address_Error;
         when Editor.Ada_Representation_Legality.Representation_Legality_Size_Target_Incompatible |
              Editor.Ada_Representation_Legality.Representation_Legality_Alignment_Target_Incompatible |
              Editor.Ada_Representation_Legality.Representation_Legality_Storage_Size_Target_Incompatible =>
            return Representation_Diagnostic_Size_Alignment_Storage_Error;
         when Editor.Ada_Representation_Legality.Representation_Legality_Interfacing_Target_Incompatible |
              Editor.Ada_Representation_Legality.Representation_Legality_Convention_Identifier_Required |
              Editor.Ada_Representation_Legality.Representation_Legality_Convention_Identifier_Unknown |
              Editor.Ada_Representation_Legality.Representation_Legality_Import_Export_Boolean_Value_Required |
              Editor.Ada_Representation_Legality.Representation_Legality_Link_Name_String_Value_Required |
              Editor.Ada_Representation_Legality.Representation_Legality_Import_Export_Conflict |
              Editor.Ada_Representation_Legality.Representation_Legality_Link_Name_Requires_Import_Export =>
            return Representation_Diagnostic_Interfacing_Error;
         when Editor.Ada_Representation_Legality.Representation_Legality_Stream_Target_Incompatible |
              Editor.Ada_Representation_Legality.Representation_Legality_Stream_Subprogram_Required |
              Editor.Ada_Representation_Legality.Representation_Legality_Stream_Subprogram_Malformed |
              Editor.Ada_Representation_Legality.Representation_Legality_Stream_Subprogram_Profile_Unknown |
              Editor.Ada_Representation_Legality.Representation_Legality_Stream_Subprogram_Profile_Mismatch =>
            return Representation_Diagnostic_Stream_Profile_Error;
         when Editor.Ada_Representation_Legality.Representation_Legality_Operational_Target_Incompatible |
              Editor.Ada_Representation_Legality.Representation_Legality_Operational_Boolean_Value_Required |
              Editor.Ada_Representation_Legality.Representation_Legality_Operational_Order_Value_Required =>
            return Representation_Diagnostic_Operational_Error;
         when others =>
            return Representation_Diagnostic_Unknown;
      end case;
   end Legality_Kind;



   function Selected_Target_Kind
     (Status : Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Status)
      return Representation_Diagnostic_Kind
   is
      use type Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Status;
   begin
      case Status is
         when Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Limited_View =>
            return Representation_Diagnostic_Selected_Target_Limited_View;
         when Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Private_View =>
            return Representation_Diagnostic_Selected_Target_Private_View;
         when Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Prefix_Missing =>
            return Representation_Diagnostic_Selected_Target_Prefix_Missing;
         when Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Prefix_Ambiguous =>
            return Representation_Diagnostic_Selected_Target_Prefix_Ambiguous;
         when Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Prefix_Overflow =>
            return Representation_Diagnostic_Selected_Target_Prefix_Overflow;
         when Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Selector_Missing =>
            return Representation_Diagnostic_Selected_Target_Selector_Missing;
         when Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Selector_Ambiguous =>
            return Representation_Diagnostic_Selected_Target_Selector_Ambiguous;
         when Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Unresolved |
              Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Unknown =>
            return Representation_Diagnostic_Selected_Target_Unresolved;
         when others =>
            return Representation_Diagnostic_Unknown;
      end case;
   end Selected_Target_Kind;

   function Selected_Target_Message
     (Kind : Representation_Diagnostic_Kind) return String is
   begin
      case Kind is
         when Representation_Diagnostic_Selected_Target_Limited_View =>
            return "representation target selected-name prefix denotes a limited incomplete view";
         when Representation_Diagnostic_Selected_Target_Private_View =>
            return "representation target selected-name prefix is hidden by private-view visibility";
         when Representation_Diagnostic_Selected_Target_Prefix_Missing =>
            return "representation target selected-name prefix is missing from visible units";
         when Representation_Diagnostic_Selected_Target_Prefix_Ambiguous =>
            return "representation target selected-name prefix is ambiguous across visible units";
         when Representation_Diagnostic_Selected_Target_Prefix_Overflow =>
            return "representation target selected-name prefix lookup exceeded bounded analysis capacity";
         when Representation_Diagnostic_Selected_Target_Selector_Missing =>
            return "representation target selector was not found in the resolved prefix";
         when Representation_Diagnostic_Selected_Target_Selector_Ambiguous =>
            return "representation target selector is ambiguous in the resolved prefix";
         when Representation_Diagnostic_Selected_Target_Unresolved =>
            return "representation target selected-name could not be resolved";
         when others =>
            return "representation target selected-name requires semantic review";
      end case;
   end Selected_Target_Message;

   function Exact_Record_Layout_Kind
     (Status : Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Status)
      return Representation_Diagnostic_Kind
   is
      use type Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Status;
   begin
      case Status is
         when Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Size_Clause_Exceeded =>
            return Representation_Diagnostic_Record_Layout_Size_Exceeded;
         when Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Size_Clause_Padded =>
            return Representation_Diagnostic_Record_Layout_Size_Padded;
         when Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Alignment_Not_Power_Of_Two |
              Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Alignment_Static_Error |
              Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Alignment_Target_Error =>
            return Representation_Diagnostic_Record_Layout_Alignment_Error;
         when Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Component_Error =>
            return Representation_Diagnostic_Record_Layout_Component_Error_Exact;
         when others =>
            return Representation_Diagnostic_Unknown;
      end case;
   end Exact_Record_Layout_Kind;

   function Exact_Record_Layout_Message
     (Kind : Representation_Diagnostic_Kind) return String is
   begin
      case Kind is
         when Representation_Diagnostic_Record_Layout_Size_Exceeded =>
            return "record Size clause is smaller than the occupied representation bit span";
         when Representation_Diagnostic_Record_Layout_Size_Padded =>
            return "record Size clause includes padding beyond the occupied representation bit span";
         when Representation_Diagnostic_Record_Layout_Alignment_Error =>
            return "record Alignment clause is not a valid exact layout alignment";
         when Representation_Diagnostic_Record_Layout_Component_Error_Exact =>
            return "exact record layout validation inherits a component layout error";
         when others =>
            return "exact record layout requires semantic review";
      end case;
   end Exact_Record_Layout_Message;

   function Exact_Record_Layout_Severity
     (Kind : Representation_Diagnostic_Kind)
      return Representation_Diagnostic_Severity is
   begin
      case Kind is
         when Representation_Diagnostic_Record_Layout_Size_Padded =>
            return Representation_Diagnostic_Severity_Info;
         when others =>
            return Representation_Diagnostic_Error;
      end case;
   end Exact_Record_Layout_Severity;



   function Stream_Profile_Kind
     (Status : Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Status)
      return Representation_Diagnostic_Kind
   is
      use type Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Status;
   begin
      case Status is
         when Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Target_Error =>
            return Representation_Diagnostic_Stream_Target_Type_Error;
         when Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Handler_Missing =>
            return Representation_Diagnostic_Stream_Handler_Missing;
         when Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Handler_Ambiguous =>
            return Representation_Diagnostic_Stream_Handler_Ambiguous;
         when Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Arity_Mismatch =>
            return Representation_Diagnostic_Stream_Handler_Arity_Mismatch;
         when Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Result_Mismatch =>
            return Representation_Diagnostic_Stream_Handler_Result_Mismatch;
         when Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Mode_Requires_Procedure |
              Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Mode_Requires_Function =>
            return Representation_Diagnostic_Stream_Handler_Mode_Mismatch;
         when Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Profile_Unknown |
              Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Handler_Malformed |
              Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Unknown =>
            return Representation_Diagnostic_Stream_Handler_Unknown;
         when others =>
            return Representation_Diagnostic_Unknown;
      end case;
   end Stream_Profile_Kind;

   function Stream_Profile_Message
     (Kind : Representation_Diagnostic_Kind) return String is
   begin
      case Kind is
         when Representation_Diagnostic_Stream_Target_Type_Error =>
            return "stream attribute target type is not compatible with stream attribute conformance";
         when Representation_Diagnostic_Stream_Handler_Missing =>
            return "stream attribute handler designator is missing";
         when Representation_Diagnostic_Stream_Handler_Ambiguous =>
            return "stream attribute handler designator resolves to multiple callable profiles";
         when Representation_Diagnostic_Stream_Handler_Arity_Mismatch =>
            return "stream attribute handler profile has the wrong number of parameters";
         when Representation_Diagnostic_Stream_Handler_Result_Mismatch =>
            return "stream Input handler result subtype does not match the target type";
         when Representation_Diagnostic_Stream_Handler_Mode_Mismatch =>
            return "stream attribute handler must be a procedure or function matching the attribute kind";
         when Representation_Diagnostic_Stream_Handler_Unknown =>
            return "stream attribute handler profile could not be proven conformant";
         when others =>
            return "stream attribute profile requires semantic review";
      end case;
   end Stream_Profile_Message;

   procedure Add_Stream_Profile_Diagnostics
     (Model : in out Representation_Diagnostic_Model;
      Stream_Profiles : Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Model)
   is
   begin
      for Index in 1 .. Editor.Ada_Stream_Attribute_Profile_Conformance.Check_Count (Stream_Profiles) loop
         declare
            Info : constant Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Info :=
              Editor.Ada_Stream_Attribute_Profile_Conformance.Check_At (Stream_Profiles, Index);
            Kind : constant Representation_Diagnostic_Kind := Stream_Profile_Kind (Info.Status);
         begin
            if Kind /= Representation_Diagnostic_Unknown then
               Add
                 (Model, Kind, Representation_Diagnostic_Error,
                  Info.Clause_Node, Editor.Ada_Syntax_Tree.No_Node,
                  Info.Target_Name, Info.Handler_Name, Info.Source_Line,
                  Stream_Profile_Message (Kind), Info.Fingerprint);
            end if;
         end;
      end loop;
   end Add_Stream_Profile_Diagnostics;

   procedure Add_Exact_Record_Layout_Diagnostics
     (Model : in out Representation_Diagnostic_Model;
      Exact_Layout : Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Model)
   is
   begin
      for Index in 1 .. Editor.Ada_Record_Layout_Exact_Validation.Check_Count (Exact_Layout) loop
         declare
            Info : constant Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Info :=
              Editor.Ada_Record_Layout_Exact_Validation.Check_At (Exact_Layout, Index);
            Kind : constant Representation_Diagnostic_Kind :=
              Exact_Record_Layout_Kind (Info.Status);
         begin
            if Kind /= Representation_Diagnostic_Unknown then
               Add
                 (Model, Kind, Exact_Record_Layout_Severity (Kind),
                  Info.Clause_Node, Editor.Ada_Syntax_Tree.No_Node,
                  Info.Target_Name, To_Unbounded_String ("record layout"),
                  Info.Source_Line, Exact_Record_Layout_Message (Kind),
                  Info.Fingerprint);
            end if;
         end;
      end loop;
   end Add_Exact_Record_Layout_Diagnostics;

   procedure Add_Selected_Target_Diagnostics
     (Model : in out Representation_Diagnostic_Model;
      Selected_Targets : Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Model)
   is
   begin
      for Index in 1 .. Editor.Ada_Selected_Representation_Targets.Target_Count (Selected_Targets) loop
         declare
            Info : constant Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Info :=
              Editor.Ada_Selected_Representation_Targets.Target_At (Selected_Targets, Index);
            Kind : constant Representation_Diagnostic_Kind := Selected_Target_Kind (Info.Status);
         begin
            if Kind /= Representation_Diagnostic_Unknown then
               Add
                 (Model, Kind, Representation_Diagnostic_Error,
                  Info.Representation_Target.Clause_Node.Clause_Node,
                  Editor.Ada_Syntax_Tree.No_Node,
                  Info.Target_Name, Info.Selector_Name,
                  Info.Representation_Target.Clause_Node.Source_Line,
                  Selected_Target_Message (Kind), Info.Fingerprint);
            end if;
         end;
      end loop;
   end Add_Selected_Target_Diagnostics;

   procedure Clear (Model : in out Representation_Diagnostic_Model) is
   begin
      Model.Diagnostics.Clear;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Legality     : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Layout       : Editor.Ada_Record_Layout_Validation.Record_Layout_Model;
      Storage      : Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model;
      Operational  : Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model;
      Inheritance  : Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model;
      Freezing     : Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model)
      return Representation_Diagnostic_Model
   is
      Model : Representation_Diagnostic_Model;
      use type Editor.Ada_Representation_Legality.Representation_Legality_Status;
      use type Editor.Ada_Record_Layout_Validation.Record_Layout_Status;
      use type Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Status;
      use type Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Status;
      use type Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Status;
      use type Editor.Ada_Freezing_Interactions.Freezing_Interaction_Status;
   begin
      for Index in 1 .. Editor.Ada_Representation_Legality.Check_Count (Legality) loop
         declare
            Info : constant Editor.Ada_Representation_Legality.Representation_Legality_Info :=
              Editor.Ada_Representation_Legality.Check_At (Legality, Index);
            Kind : constant Representation_Diagnostic_Kind := Legality_Kind (Info.Status);
         begin
            if Info.Status /= Editor.Ada_Representation_Legality.Representation_Legality_Ok
              and then Kind /= Representation_Diagnostic_Unknown
            then
               Add (Model, Kind, Representation_Diagnostic_Error,
                    Info.Clause_Node, Editor.Ada_Syntax_Tree.No_Node,
                    Info.Target_Name, Info.Item_Text, Info.Source_Line,
                    "representation property legality error", Info.Fingerprint);
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Record_Layout_Validation.Check_Count (Layout) loop
         declare
            Info : constant Editor.Ada_Record_Layout_Validation.Record_Layout_Info :=
              Editor.Ada_Record_Layout_Validation.Check_At (Layout, Index);
         begin
            if Info.Status = Editor.Ada_Record_Layout_Validation.Record_Layout_Overlap then
               Add (Model, Representation_Diagnostic_Record_Layout_Overlap,
                    Representation_Diagnostic_Error,
                    Info.Component_Node, Info.Overlap_Node,
                    Info.Target_Name, Info.Component_Name, Info.Source_Line,
                    "record representation component layout overlaps another component", Info.Fingerprint);
            elsif Info.Status = Editor.Ada_Record_Layout_Validation.Record_Layout_Static_Error then
               Add (Model, Representation_Diagnostic_Record_Layout_Static_Error,
                    Representation_Diagnostic_Error,
                    Info.Component_Node, Info.Parent_Clause,
                    Info.Target_Name, Info.Component_Name, Info.Source_Line,
                    "record representation component layout contains a static-value error", Info.Fingerprint);
            elsif Info.Status in
              Editor.Ada_Record_Layout_Validation.Record_Layout_Size_Exceeded |
              Editor.Ada_Record_Layout_Validation.Record_Layout_Alignment_Warning
            then
               Add (Model, Representation_Diagnostic_Record_Layout_Overlap,
                    Representation_Diagnostic_Warning,
                    Info.Component_Node, Info.Parent_Clause,
                    Info.Target_Name, Info.Component_Name, Info.Source_Line,
                    "record representation component layout requires size/alignment review", Info.Fingerprint);
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Record_Storage_Order_Rules.Rule_Count (Storage) loop
         declare
            Info : constant Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Info :=
              Editor.Ada_Record_Storage_Order_Rules.Rule_At (Storage, Index);
         begin
            if Info.Status = Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Order_Conflict then
               Add (Model, Representation_Diagnostic_Storage_Order_Conflict,
                    Representation_Diagnostic_Error,
                    Info.Component_Node, Info.Bit_Order_Clause,
                    Info.Target_Name, Info.Component_Name, Info.Source_Line,
                    "Bit_Order and Scalar_Storage_Order metadata conflict for this record component layout", Info.Fingerprint);
            elsif Info.Status in
              Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Operational_Error |
              Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Layout_Error
            then
               Add (Model, Representation_Diagnostic_Storage_Order_Conflict,
                    Representation_Diagnostic_Warning,
                    Info.Component_Node, Info.Scalar_Order_Clause,
                    Info.Target_Name, Info.Component_Name, Info.Source_Line,
                    "storage-order rule inherits an operational or layout error", Info.Fingerprint);
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Operational_Attribute_Rules.Rule_Count (Operational) loop
         declare
            Info : constant Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Info :=
              Editor.Ada_Operational_Attribute_Rules.Rule_At (Operational, Index);
            Property : constant Unbounded_String :=
              To_Unbounded_String
                (Editor.Ada_Language_Model.Representation_Clause_Kind'Image (Info.Clause_Kind));
         begin
            if Info.Status = Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Duplicate_Property then
               Add (Model, Representation_Diagnostic_Operational_Duplicate,
                    Representation_Diagnostic_Warning,
                    Info.Clause_Node, Info.Previous_Clause,
                    Info.Target_Name, Property, Info.Source_Line,
                    "duplicate operational property on the same target", Info.Fingerprint);
            elsif Info.Status = Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Conflicting_Boolean_Value then
               Add (Model, Representation_Diagnostic_Operational_Conflict,
                    Representation_Diagnostic_Error,
                    Info.Clause_Node, Info.Previous_Clause,
                    Info.Target_Name, Property, Info.Source_Line,
                    "conflicting Boolean values for the same operational property", Info.Fingerprint);
            elsif Info.Status in
              Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Target_Error |
              Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Value_Error
            then
               Add (Model, Representation_Diagnostic_Operational_Error,
                    Representation_Diagnostic_Error,
                    Info.Clause_Node, Info.Previous_Clause,
                    Info.Target_Name, Property, Info.Source_Line,
                    "operational property target or value is invalid", Info.Fingerprint);
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Aspect_Inheritance_Rules.Rule_Count (Inheritance) loop
         declare
            Info : constant Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Info :=
              Editor.Ada_Aspect_Inheritance_Rules.Rule_At (Inheritance, Index);
            Property : constant Unbounded_String :=
              To_Unbounded_String
                (Editor.Ada_Language_Model.Representation_Clause_Kind'Image (Info.Property_Kind));
         begin
            if Info.Status = Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Explicit_Conflict then
               Add (Model, Representation_Diagnostic_Aspect_Inheritance_Conflict,
                    Representation_Diagnostic_Error,
                    Info.Clause_Node, Info.Ancestor_Clause,
                    Info.Target_Name, Property, Info.Source_Line,
                    "explicit representation/aspect override conflicts with inherited metadata", Info.Fingerprint);
            elsif Info.Status in
              Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Private_Partial_View |
              Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Private_Full_View_Override
            then
               Add (Model, Representation_Diagnostic_Aspect_Inheritance_Conflict,
                    Representation_Diagnostic_Warning,
                    Info.Clause_Node, Info.Ancestor_Clause,
                    Info.Target_Name, Property, Info.Source_Line,
                    "representation/aspect inheritance depends on private/full-view visibility", Info.Fingerprint);
            end if;
         end;
      end loop;

      for Index in 1 .. Editor.Ada_Freezing_Interactions.Interaction_Count (Freezing) loop
         declare
            Info : constant Editor.Ada_Freezing_Interactions.Freezing_Interaction_Info :=
              Editor.Ada_Freezing_Interactions.Interaction_At (Freezing, Index);
         begin
            if Info.Status = Editor.Ada_Freezing_Interactions.Freezing_Interaction_Generic_Instance_Freezes_Target then
               Add (Model, Representation_Diagnostic_Generic_Instance_Freezing,
                    Representation_Diagnostic_Severity_Info,
                    Info.Node, Editor.Ada_Syntax_Tree.No_Node,
                    Info.Name, To_Unbounded_String ("generic instance"), Info.Line,
                    "generic instantiation contributes a freezing interaction", Info.Fingerprint);
            elsif Info.Status in
              Editor.Ada_Freezing_Interactions.Freezing_Interaction_Generic_Target_Unresolved |
              Editor.Ada_Freezing_Interactions.Freezing_Interaction_Generic_Target_Ambiguous |
              Editor.Ada_Freezing_Interactions.Freezing_Interaction_Generic_Target_Not_Freezable
            then
               Add (Model, Representation_Diagnostic_Generic_Instance_Freezing,
                    Representation_Diagnostic_Error,
                    Info.Node, Editor.Ada_Syntax_Tree.No_Node,
                    Info.Name, To_Unbounded_String ("generic instance"), Info.Line,
                    "generic instantiation freezing target is unresolved, ambiguous, or not freezable", Info.Fingerprint);
            elsif Info.Status in
              Editor.Ada_Freezing_Interactions.Freezing_Interaction_Private_Full_View_Hidden |
              Editor.Ada_Freezing_Interactions.Freezing_Interaction_Private_Full_View_Unresolved
            then
               Add (Model, Representation_Diagnostic_Private_View_Freezing,
                    Representation_Diagnostic_Warning,
                    Info.Node, Editor.Ada_Syntax_Tree.No_Node,
                    Info.Name, To_Unbounded_String ("private view"), Info.Line,
                    "freezing depends on private/full-view visibility", Info.Fingerprint);
            end if;
         end;
      end loop;

      return Model;
   end Build;

   function Build_With_Selected_Targets
     (Legality     : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Layout       : Editor.Ada_Record_Layout_Validation.Record_Layout_Model;
      Storage      : Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model;
      Operational  : Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model;
      Inheritance  : Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model;
      Freezing     : Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model;
      Selected_Targets : Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Model)
      return Representation_Diagnostic_Model
   is
      Model : Representation_Diagnostic_Model :=
        Build (Legality, Layout, Storage, Operational, Inheritance, Freezing);
   begin
      Add_Selected_Target_Diagnostics (Model, Selected_Targets);
      return Model;
   end Build_With_Selected_Targets;



   function Build_With_Selected_Targets
     (Legality     : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Layout       : Editor.Ada_Record_Layout_Validation.Record_Layout_Model;
      Storage      : Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model;
      Operational  : Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model;
      Inheritance  : Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model;
      Freezing     : Editor.Ada_Freezing_Points.Freezing_Model;
      Selected_Targets : Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Model)
      return Representation_Diagnostic_Model
   is
      pragma Unreferenced (Freezing);
      Empty_Freezing : Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model;
   begin
      return Build_With_Selected_Targets
        (Legality, Layout, Storage, Operational, Inheritance, Empty_Freezing,
         Selected_Targets);
   end Build_With_Selected_Targets;

   function Build_With_Exact_Layout
     (Legality     : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Layout       : Editor.Ada_Record_Layout_Validation.Record_Layout_Model;
      Storage      : Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model;
      Operational  : Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model;
      Inheritance  : Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model;
      Freezing     : Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model;
      Exact_Layout : Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Model)
      return Representation_Diagnostic_Model
   is
      Model : Representation_Diagnostic_Model :=
        Build (Legality, Layout, Storage, Operational, Inheritance, Freezing);
   begin
      Add_Exact_Record_Layout_Diagnostics (Model, Exact_Layout);
      return Model;
   end Build_With_Exact_Layout;

   function Build_With_Selected_Targets_And_Exact_Layout
     (Legality     : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Layout       : Editor.Ada_Record_Layout_Validation.Record_Layout_Model;
      Storage      : Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model;
      Operational  : Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model;
      Inheritance  : Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model;
      Freezing     : Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model;
      Selected_Targets : Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Model;
      Exact_Layout : Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Model)
      return Representation_Diagnostic_Model
   is
      Model : Representation_Diagnostic_Model :=
        Build_With_Selected_Targets
          (Legality, Layout, Storage, Operational, Inheritance, Freezing,
           Selected_Targets);
   begin
      Add_Exact_Record_Layout_Diagnostics (Model, Exact_Layout);
      return Model;
   end Build_With_Selected_Targets_And_Exact_Layout;



   function Build_With_Stream_Profile_Conformance
     (Legality     : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Layout       : Editor.Ada_Record_Layout_Validation.Record_Layout_Model;
      Storage      : Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model;
      Operational  : Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model;
      Inheritance  : Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model;
      Freezing     : Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model;
      Stream_Profiles : Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Model)
      return Representation_Diagnostic_Model
   is
      Model : Representation_Diagnostic_Model :=
        Build (Legality, Layout, Storage, Operational, Inheritance, Freezing);
   begin
      Add_Stream_Profile_Diagnostics (Model, Stream_Profiles);
      return Model;
   end Build_With_Stream_Profile_Conformance;

   function Build_With_Selected_Targets_Exact_Layout_And_Stream_Profiles
     (Legality     : Editor.Ada_Representation_Legality.Representation_Legality_Model;
      Layout       : Editor.Ada_Record_Layout_Validation.Record_Layout_Model;
      Storage      : Editor.Ada_Record_Storage_Order_Rules.Storage_Order_Rule_Model;
      Operational  : Editor.Ada_Operational_Attribute_Rules.Operational_Rule_Model;
      Inheritance  : Editor.Ada_Aspect_Inheritance_Rules.Aspect_Inheritance_Model;
      Freezing     : Editor.Ada_Freezing_Interactions.Freezing_Interaction_Model;
      Selected_Targets : Editor.Ada_Selected_Representation_Targets.Selected_Representation_Target_Model;
      Exact_Layout : Editor.Ada_Record_Layout_Exact_Validation.Exact_Record_Layout_Model;
      Stream_Profiles : Editor.Ada_Stream_Attribute_Profile_Conformance.Stream_Profile_Conformance_Model)
      return Representation_Diagnostic_Model
   is
      Model : Representation_Diagnostic_Model :=
        Build_With_Selected_Targets_And_Exact_Layout
          (Legality, Layout, Storage, Operational, Inheritance, Freezing,
           Selected_Targets, Exact_Layout);
   begin
      Add_Stream_Profile_Diagnostics (Model, Stream_Profiles);
      return Model;
   end Build_With_Selected_Targets_Exact_Layout_And_Stream_Profiles;

   function Has_Diagnostics (Model : Representation_Diagnostic_Model) return Boolean is
   begin
      return not Model.Diagnostics.Is_Empty;
   end Has_Diagnostics;

   function Diagnostic_Count (Model : Representation_Diagnostic_Model) return Natural is
   begin
      return Natural (Model.Diagnostics.Length);
   end Diagnostic_Count;

   function Diagnostic_At
     (Model : Representation_Diagnostic_Model;
      Index : Positive) return Representation_Diagnostic_Info is
   begin
      if Index > Natural (Model.Diagnostics.Length) then
         return (others => <>);
      end if;
      return Model.Diagnostics.Element (Index);
   end Diagnostic_At;

   function Error_Count (Model : Representation_Diagnostic_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Representation_Diagnostic_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : Representation_Diagnostic_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Count_Kind
     (Model : Representation_Diagnostic_Model;
      Kind  : Representation_Diagnostic_Kind) return Natural
   is
      Total : Natural := 0;
   begin
      for Info of Model.Diagnostics loop
         if Info.Kind = Kind then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Kind;



   function Exact_Record_Layout_Diagnostic_Count
     (Model : Representation_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Representation_Diagnostic_Record_Layout_Size_Exceeded)
        + Count_Kind (Model, Representation_Diagnostic_Record_Layout_Size_Padded)
        + Count_Kind (Model, Representation_Diagnostic_Record_Layout_Alignment_Error)
        + Count_Kind (Model, Representation_Diagnostic_Record_Layout_Component_Error_Exact);
   end Exact_Record_Layout_Diagnostic_Count;

   function Exact_Record_Layout_Size_Error_Count
     (Model : Representation_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Representation_Diagnostic_Record_Layout_Size_Exceeded);
   end Exact_Record_Layout_Size_Error_Count;

   function Exact_Record_Layout_Alignment_Error_Count
     (Model : Representation_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Representation_Diagnostic_Record_Layout_Alignment_Error);
   end Exact_Record_Layout_Alignment_Error_Count;

   function Exact_Record_Layout_Component_Error_Count
     (Model : Representation_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Representation_Diagnostic_Record_Layout_Component_Error_Exact);
   end Exact_Record_Layout_Component_Error_Count;



   function Stream_Profile_Conformance_Diagnostic_Count
     (Model : Representation_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Representation_Diagnostic_Stream_Target_Type_Error)
        + Count_Kind (Model, Representation_Diagnostic_Stream_Handler_Missing)
        + Count_Kind (Model, Representation_Diagnostic_Stream_Handler_Ambiguous)
        + Count_Kind (Model, Representation_Diagnostic_Stream_Handler_Arity_Mismatch)
        + Count_Kind (Model, Representation_Diagnostic_Stream_Handler_Result_Mismatch)
        + Count_Kind (Model, Representation_Diagnostic_Stream_Handler_Mode_Mismatch)
        + Count_Kind (Model, Representation_Diagnostic_Stream_Handler_Unknown);
   end Stream_Profile_Conformance_Diagnostic_Count;

   function Stream_Profile_Target_Error_Count
     (Model : Representation_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Representation_Diagnostic_Stream_Target_Type_Error);
   end Stream_Profile_Target_Error_Count;

   function Stream_Profile_Handler_Error_Count
     (Model : Representation_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Representation_Diagnostic_Stream_Handler_Missing)
        + Count_Kind (Model, Representation_Diagnostic_Stream_Handler_Ambiguous)
        + Count_Kind (Model, Representation_Diagnostic_Stream_Handler_Arity_Mismatch)
        + Count_Kind (Model, Representation_Diagnostic_Stream_Handler_Result_Mismatch)
        + Count_Kind (Model, Representation_Diagnostic_Stream_Handler_Unknown);
   end Stream_Profile_Handler_Error_Count;

   function Stream_Profile_Mode_Error_Count
     (Model : Representation_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Representation_Diagnostic_Stream_Handler_Mode_Mismatch);
   end Stream_Profile_Mode_Error_Count;

   function Selected_Target_Diagnostic_Count
     (Model : Representation_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Representation_Diagnostic_Selected_Target_Limited_View)
        + Count_Kind (Model, Representation_Diagnostic_Selected_Target_Private_View)
        + Count_Kind (Model, Representation_Diagnostic_Selected_Target_Prefix_Missing)
        + Count_Kind (Model, Representation_Diagnostic_Selected_Target_Prefix_Ambiguous)
        + Count_Kind (Model, Representation_Diagnostic_Selected_Target_Prefix_Overflow)
        + Count_Kind (Model, Representation_Diagnostic_Selected_Target_Selector_Missing)
        + Count_Kind (Model, Representation_Diagnostic_Selected_Target_Selector_Ambiguous)
        + Count_Kind (Model, Representation_Diagnostic_Selected_Target_Unresolved);
   end Selected_Target_Diagnostic_Count;

   function Selected_Target_Limited_View_Count
     (Model : Representation_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Representation_Diagnostic_Selected_Target_Limited_View);
   end Selected_Target_Limited_View_Count;

   function Selected_Target_Private_View_Count
     (Model : Representation_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Representation_Diagnostic_Selected_Target_Private_View);
   end Selected_Target_Private_View_Count;

   function Selected_Target_Missing_Count
     (Model : Representation_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Representation_Diagnostic_Selected_Target_Prefix_Missing);
   end Selected_Target_Missing_Count;

   function Selected_Target_Ambiguous_Count
     (Model : Representation_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Representation_Diagnostic_Selected_Target_Prefix_Ambiguous)
        + Count_Kind (Model, Representation_Diagnostic_Selected_Target_Prefix_Overflow);
   end Selected_Target_Ambiguous_Count;

   function Selected_Target_Selector_Error_Count
     (Model : Representation_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Representation_Diagnostic_Selected_Target_Selector_Missing)
        + Count_Kind (Model, Representation_Diagnostic_Selected_Target_Selector_Ambiguous);
   end Selected_Target_Selector_Error_Count;

   function Fingerprint (Model : Representation_Diagnostic_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Representation_Diagnostics;
