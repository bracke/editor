with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Accessibility_Precision_Legality is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Level;

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Status;
   use type Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Status;
   use type Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Status;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 283) + (B * 47) + 1128) mod 1_000_000_007;
   end Mix;

   function Kind_Slot (Kind : Accessibility_Precision_Context_Kind) return Natural is
   begin
      return Accessibility_Precision_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : Accessibility_Precision_Status) return Natural is
   begin
      return Accessibility_Precision_Status'Pos (Status) + 1;
   end Status_Slot;

   function Level_Slot (Level : Accessibility_Level) return Natural is
   begin
      return Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Level'Pos (Level) + 1;
   end Level_Slot;

   function Base_Status_Slot (Status : Accessibility_Legality_Status) return Natural is
   begin
      return Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Status'Pos (Status) + 1;
   end Base_Status_Slot;

   function Generic_Status_Slot (Status : Generic_Body_Expansion_Status) return Natural is
   begin
      return Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Status'Pos (Status) + 1;
   end Generic_Status_Slot;

   function Record_Status_Slot (Status : Record_Aggregate_Legality_Status) return Natural is
   begin
      return Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Status'Pos (Status) + 1;
   end Record_Status_Slot;

   function Level_Known (Level : Accessibility_Level) return Boolean is
   begin
      return Level /= Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Level_Unknown;
   end Level_Known;

   function Level_Compatible
     (Source_Level : Accessibility_Level;
      Target_Level : Accessibility_Level) return Boolean
   is
   begin
      if not Level_Known (Source_Level) or else not Level_Known (Target_Level) then
         return False;
      end if;

      return Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Level'Pos (Source_Level) <=
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Level'Pos (Target_Level);
   end Level_Compatible;

   function Base_Accessibility_Error (Status : Accessibility_Legality_Status) return Boolean is
   begin
      return Status in
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Null_Exclusion_Violation |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Access_Kind_Mismatch |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Target_Not_Aliased |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Level_Too_Deep |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Return_Object_Too_Short_Lived |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Anonymous_Access_Level_Unresolved |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Allocator_Designated_Subtype_Mismatch |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Access_Discriminant_Lifetime_Error |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Access_Parameter_Escapes |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Dangling_Rename_Risk |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Private_View_Barrier |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Limited_View_Barrier |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Cross_Unit_Unresolved_View |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Linked_Assignment_Error |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Linked_Return_Error |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Linked_Semantic_Error |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Linked_Staticness_Error |
        Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Indeterminate;
   end Base_Accessibility_Error;

   function Generic_Error (Status : Generic_Body_Expansion_Status) return Boolean is
   begin
      return Status in
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Private_View_Barrier |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Limited_View_Barrier |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Cross_Unit_Unresolved |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Object_Mismatch |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Object_Unknown |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Missing_Body_Contract |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Contract_Mismatch |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Overload_Error |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Accessibility_Error |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Contract_Error |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Dataflow_Error |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Initialization_Error |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Predicate_Invariant_Error |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Representation_Error |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Multiple_Semantic_Blockers |
        Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Indeterminate;
   end Generic_Error;

   function Record_Aggregate_Error (Status : Record_Aggregate_Legality_Status) return Boolean is
   begin
      return Status in
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Missing_Component |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Duplicate_Component |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Component_Type_Mismatch |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Positional_After_Named |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Missing_Discriminant |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Duplicate_Discriminant |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Discriminant_Type_Mismatch |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Unconstrained_Without_Discriminants |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Variant_Choice_Missing |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Variant_Choice_Duplicate |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Variant_Choice_Overlap |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Variant_Coverage_Incomplete |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Variant_Choice_Unreachable |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Variant_Layout_Hole |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Variant_Layout_Overlap |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Discriminant_Layout_Error |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Linked_Aggregate_Error |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Linked_Predicate_Invariant_Error |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Linked_Representation_Error |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Private_View_Barrier |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Limited_View_Barrier |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Cross_Unit_Unresolved_View |
        Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Indeterminate;
   end Record_Aggregate_Error;

   function Is_Legal (Status : Accessibility_Precision_Status) return Boolean is
   begin
      return Status in
        Accessibility_Precision_Legal_Static_Level |
        Accessibility_Precision_Legal_Dynamic_Check |
        Accessibility_Precision_Legal_Allocator_Master |
        Accessibility_Precision_Legal_Return_Level |
        Accessibility_Precision_Legal_Access_Discriminant |
        Accessibility_Precision_Legal_Generic_Substitution |
        Accessibility_Precision_Legal_Aggregate_Discriminant;
   end Is_Legal;

   function Is_Linked_Error (Status : Accessibility_Precision_Status) return Boolean is
   begin
      return Status in
        Accessibility_Precision_Linked_Accessibility_Error |
        Accessibility_Precision_Linked_Generic_Body_Error |
        Accessibility_Precision_Linked_Record_Aggregate_Error;
   end Is_Linked_Error;

   function Is_Indeterminate (Status : Accessibility_Precision_Status) return Boolean is
   begin
      return Status in
        Accessibility_Precision_Anonymous_Access_Level_Unresolved |
        Accessibility_Precision_Access_Discriminant_Unresolved |
        Accessibility_Precision_Generic_Actual_Unresolved |
        Accessibility_Precision_Aggregate_Discriminant_Unresolved |
        Accessibility_Precision_Indeterminate;
   end Is_Indeterminate;

   function Context_Fingerprint (Info : Accessibility_Precision_Context_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Source_Node) + 1);
      H := Mix (H, Natural (Info.Target_Node) + 1);
      H := Mix (H, Level_Slot (Info.Source_Level));
      H := Mix (H, Level_Slot (Info.Target_Level));
      H := Mix (H, Level_Slot (Info.Allocator_Master_Level));
      H := Mix (H, Level_Slot (Info.Designated_Object_Level));
      H := Mix (H, Level_Slot (Info.Return_Master_Level));
      H := Mix (H, Natural (Boolean'Pos (Info.Requires_Static_Check)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Requires_Dynamic_Check)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Anonymous_Access_Parameter)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Access_Parameter_Escapes)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Access_Discriminant_Context)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Allocator_Context)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Return_Context)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Generic_Actual_Context)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Aggregate_Discriminant_Context)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Designated_Subtype_Mismatch)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Private_View_Barrier)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Limited_View_Barrier)) + 1);
      H := Mix (H, Natural (Boolean'Pos (Info.Cross_Unit_Unresolved)) + 1);
      H := Mix (H, Base_Status_Slot (Info.Base_Accessibility_Status));
      H := Mix (H, Generic_Status_Slot (Info.Generic_Status));
      H := Mix (H, Record_Status_Slot (Info.Record_Aggregate_Status));
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Context_Fingerprint;

   function Row_Fingerprint (Info : Accessibility_Precision_Legality_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Source_Node) + 1);
      H := Mix (H, Natural (Info.Target_Node) + 1);
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Level_Slot (Info.Source_Level));
      H := Mix (H, Level_Slot (Info.Target_Level));
      H := Mix (H, Level_Slot (Info.Allocator_Master_Level));
      H := Mix (H, Level_Slot (Info.Designated_Object_Level));
      H := Mix (H, Level_Slot (Info.Return_Master_Level));
      H := Mix (H, Base_Status_Slot (Info.Base_Accessibility_Status));
      H := Mix (H, Generic_Status_Slot (Info.Generic_Status));
      H := Mix (H, Record_Status_Slot (Info.Record_Aggregate_Status));
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Message_For (Status : Accessibility_Precision_Status) return String is
   begin
      case Status is
         when Accessibility_Precision_Legal_Static_Level => return "accessibility levels are statically compatible";
         when Accessibility_Precision_Legal_Dynamic_Check => return "accessibility requires a permitted dynamic check";
         when Accessibility_Precision_Legal_Allocator_Master => return "allocator master outlives the target access value";
         when Accessibility_Precision_Legal_Return_Level => return "return accessibility is compatible";
         when Accessibility_Precision_Legal_Access_Discriminant => return "access discriminant lifetime is compatible";
         when Accessibility_Precision_Legal_Generic_Substitution => return "generic actual accessibility is compatible after substitution";
         when Accessibility_Precision_Legal_Aggregate_Discriminant => return "aggregate discriminant accessibility is compatible";
         when Accessibility_Precision_Anonymous_Access_Level_Too_Deep => return "anonymous access parameter level is deeper than the target permits";
         when Accessibility_Precision_Anonymous_Access_Level_Unresolved => return "anonymous access parameter accessibility level is unresolved";
         when Accessibility_Precision_Access_Parameter_Escapes => return "anonymous access parameter may escape its master";
         when Accessibility_Precision_Allocator_Master_Too_Short => return "allocator master is too short-lived for the target";
         when Accessibility_Precision_Allocator_Designated_Subtype_Mismatch => return "allocator designated subtype is incompatible";
         when Accessibility_Precision_Return_Access_Too_Short_Lived => return "returned access value may designate a shorter-lived object";
         when Accessibility_Precision_Return_Object_Too_Short_Lived => return "returned object may outlive an access-dependent component";
         when Accessibility_Precision_Access_Discriminant_Too_Short_Lived => return "access discriminant designates a shorter-lived object";
         when Accessibility_Precision_Access_Discriminant_Unresolved => return "access discriminant accessibility is unresolved";
         when Accessibility_Precision_Access_Conversion_Level_Too_Deep => return "access conversion source level is too deep";
         when Accessibility_Precision_Renaming_Dangling_Risk => return "renaming may leave a dangling access alias";
         when Accessibility_Precision_Generic_Actual_Too_Short_Lived => return "generic actual accessibility is too short-lived for the formal";
         when Accessibility_Precision_Generic_Actual_Unresolved => return "generic actual accessibility is unresolved";
         when Accessibility_Precision_Aggregate_Discriminant_Lifetime_Error => return "aggregate discriminant lifetime is invalid";
         when Accessibility_Precision_Aggregate_Discriminant_Unresolved => return "aggregate discriminant accessibility is unresolved";
         when Accessibility_Precision_Private_View_Barrier => return "private view prevents precise accessibility proof";
         when Accessibility_Precision_Limited_View_Barrier => return "limited view prevents precise accessibility proof";
         when Accessibility_Precision_Cross_Unit_Unresolved_View => return "cross-unit view is unresolved for accessibility proof";
         when Accessibility_Precision_Linked_Accessibility_Error => return "base accessibility legality blocks precision proof";
         when Accessibility_Precision_Linked_Generic_Body_Error => return "generic body expansion blocks accessibility proof";
         when Accessibility_Precision_Linked_Record_Aggregate_Error => return "record aggregate legality blocks accessibility proof";
         when Accessibility_Precision_Indeterminate => return "accessibility precision is indeterminate";
         when Accessibility_Precision_Not_Checked => return "accessibility precision has not been checked";
      end case;
   end Message_For;

   function Detail_For (Info : Accessibility_Precision_Context_Info; Status : Accessibility_Precision_Status) return String is
      pragma Unreferenced (Status);
   begin
      return "kind=" & Accessibility_Precision_Context_Kind'Image (Info.Kind) &
        ", source_level=" & Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Level'Image (Info.Source_Level) &
        ", target_level=" & Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Level'Image (Info.Target_Level) &
        ", base=" & Editor.Ada_Accessibility_Lifetime_Legality.Accessibility_Legality_Status'Image (Info.Base_Accessibility_Status) &
        ", generic=" & Editor.Ada_Generic_Instance_Body_Semantic_Expansion.Generic_Body_Expansion_Status'Image (Info.Generic_Status) &
        ", aggregate=" & Editor.Ada_Record_Variant_Aggregate_Legality.Record_Aggregate_Legality_Status'Image (Info.Record_Aggregate_Status);
   end Detail_For;

   function Classify (Info : Accessibility_Precision_Context_Info) return Accessibility_Precision_Status is
   begin
      if Info.Private_View_Barrier then
         return Accessibility_Precision_Private_View_Barrier;
      elsif Info.Limited_View_Barrier then
         return Accessibility_Precision_Limited_View_Barrier;
      elsif Info.Cross_Unit_Unresolved then
         return Accessibility_Precision_Cross_Unit_Unresolved_View;
      elsif Base_Accessibility_Error (Info.Base_Accessibility_Status) then
         return Accessibility_Precision_Linked_Accessibility_Error;
      elsif Info.Generic_Actual_Context and then Generic_Error (Info.Generic_Status) then
         return Accessibility_Precision_Linked_Generic_Body_Error;
      elsif Info.Aggregate_Discriminant_Context and then Record_Aggregate_Error (Info.Record_Aggregate_Status) then
         return Accessibility_Precision_Linked_Record_Aggregate_Error;
      elsif Info.Designated_Subtype_Mismatch and then Info.Allocator_Context then
         return Accessibility_Precision_Allocator_Designated_Subtype_Mismatch;
      elsif Info.Access_Parameter_Escapes then
         return Accessibility_Precision_Access_Parameter_Escapes;
      elsif Info.Kind = Accessibility_Precision_Context_Anonymous_Access_Parameter then
         if not Level_Known (Info.Source_Level) or else not Level_Known (Info.Target_Level) then
            return Accessibility_Precision_Anonymous_Access_Level_Unresolved;
         elsif not Level_Compatible (Info.Source_Level, Info.Target_Level) then
            return Accessibility_Precision_Anonymous_Access_Level_Too_Deep;
         elsif Info.Requires_Dynamic_Check then
            return Accessibility_Precision_Legal_Dynamic_Check;
         else
            return Accessibility_Precision_Legal_Static_Level;
         end if;
      elsif Info.Allocator_Context then
         if not Level_Known (Info.Allocator_Master_Level) or else not Level_Known (Info.Target_Level) then
            return Accessibility_Precision_Indeterminate;
         elsif not Level_Compatible (Info.Allocator_Master_Level, Info.Target_Level) then
            return Accessibility_Precision_Allocator_Master_Too_Short;
         else
            return Accessibility_Precision_Legal_Allocator_Master;
         end if;
      elsif Info.Return_Context and then Info.Kind = Accessibility_Precision_Context_Return_Access then
         if not Level_Known (Info.Designated_Object_Level) or else not Level_Known (Info.Return_Master_Level) then
            return Accessibility_Precision_Indeterminate;
         elsif not Level_Compatible (Info.Designated_Object_Level, Info.Return_Master_Level) then
            return Accessibility_Precision_Return_Access_Too_Short_Lived;
         else
            return Accessibility_Precision_Legal_Return_Level;
         end if;
      elsif Info.Return_Context and then Info.Kind = Accessibility_Precision_Context_Return_Object then
         if not Level_Known (Info.Designated_Object_Level) or else not Level_Known (Info.Return_Master_Level) then
            return Accessibility_Precision_Indeterminate;
         elsif not Level_Compatible (Info.Designated_Object_Level, Info.Return_Master_Level) then
            return Accessibility_Precision_Return_Object_Too_Short_Lived;
         else
            return Accessibility_Precision_Legal_Return_Level;
         end if;
      elsif Info.Access_Discriminant_Context then
         if not Level_Known (Info.Designated_Object_Level) or else not Level_Known (Info.Target_Level) then
            return Accessibility_Precision_Access_Discriminant_Unresolved;
         elsif not Level_Compatible (Info.Designated_Object_Level, Info.Target_Level) then
            return Accessibility_Precision_Access_Discriminant_Too_Short_Lived;
         else
            return Accessibility_Precision_Legal_Access_Discriminant;
         end if;
      elsif Info.Kind = Accessibility_Precision_Context_Access_Conversion then
         if not Level_Known (Info.Source_Level) or else not Level_Known (Info.Target_Level) then
            return Accessibility_Precision_Indeterminate;
         elsif not Level_Compatible (Info.Source_Level, Info.Target_Level) then
            return Accessibility_Precision_Access_Conversion_Level_Too_Deep;
         else
            return Accessibility_Precision_Legal_Static_Level;
         end if;
      elsif Info.Kind = Accessibility_Precision_Context_Renaming then
         if not Level_Known (Info.Source_Level) or else not Level_Known (Info.Target_Level) then
            return Accessibility_Precision_Indeterminate;
         elsif not Level_Compatible (Info.Source_Level, Info.Target_Level) then
            return Accessibility_Precision_Renaming_Dangling_Risk;
         else
            return Accessibility_Precision_Legal_Static_Level;
         end if;
      elsif Info.Generic_Actual_Context then
         if not Level_Known (Info.Source_Level) or else not Level_Known (Info.Target_Level) then
            return Accessibility_Precision_Generic_Actual_Unresolved;
         elsif not Level_Compatible (Info.Source_Level, Info.Target_Level) then
            return Accessibility_Precision_Generic_Actual_Too_Short_Lived;
         else
            return Accessibility_Precision_Legal_Generic_Substitution;
         end if;
      elsif Info.Aggregate_Discriminant_Context then
         if not Level_Known (Info.Designated_Object_Level) or else not Level_Known (Info.Target_Level) then
            return Accessibility_Precision_Aggregate_Discriminant_Unresolved;
         elsif not Level_Compatible (Info.Designated_Object_Level, Info.Target_Level) then
            return Accessibility_Precision_Aggregate_Discriminant_Lifetime_Error;
         else
            return Accessibility_Precision_Legal_Aggregate_Discriminant;
         end if;
      elsif Info.Requires_Dynamic_Check then
         return Accessibility_Precision_Legal_Dynamic_Check;
      elsif Level_Known (Info.Source_Level) and then Level_Known (Info.Target_Level) then
         if Level_Compatible (Info.Source_Level, Info.Target_Level) then
            return Accessibility_Precision_Legal_Static_Level;
         else
            return Accessibility_Precision_Access_Conversion_Level_Too_Deep;
         end if;
      else
         return Accessibility_Precision_Indeterminate;
      end if;
   end Classify;

   procedure Append_Row
     (Model : in out Accessibility_Precision_Legality_Model;
      Info  : Accessibility_Precision_Context_Info)
   is
      Status : constant Accessibility_Precision_Status := Classify (Info);
      Row    : Accessibility_Precision_Legality_Info;
   begin
      Row.Id := Accessibility_Precision_Legality_Id (Natural (Model.Items.Length) + 1);
      Row.Context := Info.Id;
      Row.Kind := Info.Kind;
      Row.Node := Info.Node;
      Row.Source_Node := Info.Source_Node;
      Row.Target_Node := Info.Target_Node;
      Row.Object_Name := Info.Object_Name;
      Row.Status := Status;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String (Detail_For (Info, Status));
      Row.Source_Level := Info.Source_Level;
      Row.Target_Level := Info.Target_Level;
      Row.Allocator_Master_Level := Info.Allocator_Master_Level;
      Row.Designated_Object_Level := Info.Designated_Object_Level;
      Row.Return_Master_Level := Info.Return_Master_Level;
      Row.Base_Accessibility_Status := Info.Base_Accessibility_Status;
      Row.Generic_Status := Info.Generic_Status;
      Row.Record_Aggregate_Status := Info.Record_Aggregate_Status;
      Row.Start_Line := Info.Start_Line;
      Row.Start_Column := Info.Start_Column;
      Row.End_Line := Info.End_Line;
      Row.End_Column := Info.End_Column;
      Row.Source_Fingerprint := Info.Source_Fingerprint;
      Row.Fingerprint := Row_Fingerprint (Row);
      Model.Items.Append (Row);

      if Is_Legal (Status) then
         Model.Legal_Total := Model.Legal_Total + 1;
      else
         Model.Error_Total := Model.Error_Total + 1;
      end if;
      if Status = Accessibility_Precision_Legal_Dynamic_Check then
         Model.Dynamic_Check_Total := Model.Dynamic_Check_Total + 1;
      end if;
      if Status in Accessibility_Precision_Anonymous_Access_Level_Too_Deep |
        Accessibility_Precision_Anonymous_Access_Level_Unresolved |
        Accessibility_Precision_Access_Parameter_Escapes
      then
         Model.Anonymous_Access_Error_Total := Model.Anonymous_Access_Error_Total + 1;
      end if;
      if Status in Accessibility_Precision_Allocator_Master_Too_Short |
        Accessibility_Precision_Allocator_Designated_Subtype_Mismatch
      then
         Model.Allocator_Error_Total := Model.Allocator_Error_Total + 1;
      end if;
      if Status in Accessibility_Precision_Return_Access_Too_Short_Lived |
        Accessibility_Precision_Return_Object_Too_Short_Lived
      then
         Model.Return_Error_Total := Model.Return_Error_Total + 1;
      end if;
      if Status in Accessibility_Precision_Access_Discriminant_Too_Short_Lived |
        Accessibility_Precision_Access_Discriminant_Unresolved |
        Accessibility_Precision_Aggregate_Discriminant_Lifetime_Error |
        Accessibility_Precision_Aggregate_Discriminant_Unresolved
      then
         Model.Discriminant_Error_Total := Model.Discriminant_Error_Total + 1;
      end if;
      if Status in Accessibility_Precision_Generic_Actual_Too_Short_Lived |
        Accessibility_Precision_Generic_Actual_Unresolved |
        Accessibility_Precision_Linked_Generic_Body_Error
      then
         Model.Generic_Error_Total := Model.Generic_Error_Total + 1;
      end if;
      if Is_Linked_Error (Status) then
         Model.Linked_Error_Total := Model.Linked_Error_Total + 1;
      end if;
      if Is_Indeterminate (Status) then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Row.Fingerprint);
   end Append_Row;

   procedure Clear (Model : in out Accessibility_Precision_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model : in out Accessibility_Precision_Context_Model;
      Info  : Accessibility_Precision_Context_Info)
   is
      Copy : Accessibility_Precision_Context_Info := Info;
   begin
      if Copy.Id = No_Accessibility_Precision_Context then
         Copy.Id := Accessibility_Precision_Context_Id (Natural (Model.Contexts.Length) + 1);
      end if;
      Model.Contexts.Append (Copy);
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Context_Fingerprint (Copy));
   end Add_Context;

   function Context_Count (Model : Accessibility_Precision_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Accessibility_Precision_Context_Model;
      Index : Positive) return Accessibility_Precision_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Accessibility_Precision_Context_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Accessibility_Precision_Context_Model) return Accessibility_Precision_Legality_Model
   is
      Model : Accessibility_Precision_Legality_Model;
   begin
      for C of Contexts.Contexts loop
         Append_Row (Model, C);
      end loop;
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Contexts.Result_Fingerprint);
      return Model;
   end Build;

   function Legality_Count (Model : Accessibility_Precision_Legality_Model) return Natural is
   begin
      return Natural (Model.Items.Length);
   end Legality_Count;

   function Legality_At
     (Model : Accessibility_Precision_Legality_Model;
      Index : Positive) return Accessibility_Precision_Legality_Info is
   begin
      return Model.Items.Element (Index);
   end Legality_At;

   function First_For_Node
     (Model : Accessibility_Precision_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Accessibility_Precision_Legality_Info
   is
   begin
      for Row of Model.Items loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Accessibility_Precision_Legality_Model;
      Status : Accessibility_Precision_Status) return Accessibility_Precision_Result_Set
   is
      Result : Accessibility_Precision_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Result.Items.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Accessibility_Precision_Legality_Model;
      Kind  : Accessibility_Precision_Context_Kind) return Accessibility_Precision_Result_Set
   is
      Result : Accessibility_Precision_Result_Set;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Result.Items.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Kind;

   function Rows_For_Object
     (Model : Accessibility_Precision_Legality_Model;
      Name  : String) return Accessibility_Precision_Result_Set
   is
      Result : Accessibility_Precision_Result_Set;
   begin
      for Row of Model.Items loop
         if To_String (Row.Object_Name) = Name then
            Result.Items.Append (Row);
            Result.Fingerprint := Mix (Result.Fingerprint, Row.Fingerprint);
         end if;
      end loop;
      return Result;
   end Rows_For_Object;

   function Result_Count (Results : Accessibility_Precision_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Accessibility_Precision_Result_Set;
      Index   : Positive) return Accessibility_Precision_Legality_Info is
   begin
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Accessibility_Precision_Legality_Model;
      Status : Accessibility_Precision_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Accessibility_Precision_Legality_Model;
      Kind  : Accessibility_Precision_Context_Kind) return Natural
   is
      Count : Natural := 0;
   begin
      for Row of Model.Items loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Legal_Count (Model : Accessibility_Precision_Legality_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Accessibility_Precision_Legality_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Dynamic_Check_Count (Model : Accessibility_Precision_Legality_Model) return Natural is
   begin
      return Model.Dynamic_Check_Total;
   end Dynamic_Check_Count;

   function Anonymous_Access_Error_Count (Model : Accessibility_Precision_Legality_Model) return Natural is
   begin
      return Model.Anonymous_Access_Error_Total;
   end Anonymous_Access_Error_Count;

   function Allocator_Error_Count (Model : Accessibility_Precision_Legality_Model) return Natural is
   begin
      return Model.Allocator_Error_Total;
   end Allocator_Error_Count;

   function Return_Error_Count (Model : Accessibility_Precision_Legality_Model) return Natural is
   begin
      return Model.Return_Error_Total;
   end Return_Error_Count;

   function Discriminant_Error_Count (Model : Accessibility_Precision_Legality_Model) return Natural is
   begin
      return Model.Discriminant_Error_Total;
   end Discriminant_Error_Count;

   function Generic_Error_Count (Model : Accessibility_Precision_Legality_Model) return Natural is
   begin
      return Model.Generic_Error_Total;
   end Generic_Error_Count;

   function Linked_Error_Count (Model : Accessibility_Precision_Legality_Model) return Natural is
   begin
      return Model.Linked_Error_Total;
   end Linked_Error_Count;

   function Indeterminate_Count (Model : Accessibility_Precision_Legality_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Accessibility_Precision_Legality_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

   function Has_Legality (Info : Accessibility_Precision_Legality_Info) return Boolean is
   begin
      return Info.Id /= No_Accessibility_Precision_Legality;
   end Has_Legality;

end Editor.Ada_Accessibility_Precision_Legality;
