with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Cross_Unit_Semantic_Closure is

   pragma Suppress (Overflow_Check);

   package AL renames Editor.Ada_Assignment_Legality;
   package RL renames Editor.Ada_Return_Legality;
   package EL renames Editor.Ada_Conversion_Access_Aggregate_Legality;
   package FL renames Editor.Ada_Control_Flow_Legality;
   package TL renames Editor.Ada_Tasking_Protected_Legality;
   package TD renames Editor.Ada_Tagged_Derived_Legality;
   package GI renames Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
   package CU renames Editor.Ada_Cross_Unit_Closure;
   package LU renames Editor.Ada_Cross_Unit_Lookup_Integration;

   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type AL.Assignment_Context_Id;
   use type EL.Semantic_Context_Id;
   use type FL.Flow_Context_Id;
   use type GI.Instance_Context_Id;
   use type LU.Cross_Unit_Lookup_Id;
   use type RL.Return_Context_Id;
   use type TD.Tagged_Context_Id;
   use type TL.Tasking_Context_Id;

   function Mix (Left, Right : Natural) return Natural is
      type Hash_Value is mod 2 ** 32;
      Mixed : constant Hash_Value :=
        Hash_Value (Left) * 1_315_423_911
        + Hash_Value (Right) * 2_654_435_761
        + 113;
   begin
      return Natural (Mixed mod Hash_Value (2_147_483_647));
   end Mix;

   function Normalize (Value : Unbounded_String) return Unbounded_String is
   begin
      return To_Unbounded_String
        (Ada.Characters.Handling.To_Lower (To_String (Value)));
   end Normalize;

   function Kind_Slot (Kind : Cross_Unit_Semantic_Context_Kind) return Natural is
   begin
      return Cross_Unit_Semantic_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : Cross_Unit_Semantic_Status) return Natural is
   begin
      return Cross_Unit_Semantic_Status'Pos (Status) + 1;
   end Status_Slot;

   function Context_Fingerprint (Context : Cross_Unit_Semantic_Context_Info) return Natural is
      H : Natural := Natural (Context.Id) + 1;
   begin
      H := Mix (H, Kind_Slot (Context.Kind));
      H := Mix (H, Natural (Context.Node) + 1);
      H := Mix (H, Length (Context.Normalized_Source_Unit_Name) + 1);
      H := Mix (H, Length (Context.Normalized_Target_Unit_Name) + 1);
      H := Mix (H, Length (Context.Normalized_Lookup_Name) + 1);
      H := Mix (H, Boolean'Pos (Context.Requires_Cross_Unit_Dependency) + 1);
      H := Mix (H, Boolean'Pos (Context.Requires_Cross_Unit_Lookup) + 1);
      H := Mix (H, CU.Cross_Unit_Link_Status'Pos (Context.Dependency_Status) + 1);
      H := Mix (H, LU.Cross_Unit_Lookup_Status'Pos (Context.Lookup_Status) + 1);
      H := Mix (H, Context.Dependency_Fingerprint + 1);
      H := Mix (H, Context.Lookup_Fingerprint + 1);
      H := Mix (H, Natural (Context.Linked_Assignment) + 1);
      H := Mix (H, Natural (Context.Linked_Return) + 1);
      H := Mix (H, Natural (Context.Linked_Expression) + 1);
      H := Mix (H, Natural (Context.Linked_Flow) + 1);
      H := Mix (H, Natural (Context.Linked_Tasking) + 1);
      H := Mix (H, Natural (Context.Linked_Tagged) + 1);
      H := Mix (H, Natural (Context.Linked_Instance) + 1);
      H := Mix (H, Context.Start_Line);
      H := Mix (H, Context.Start_Column);
      H := Mix (H, Context.End_Line);
      H := Mix (H, Context.End_Column);
      H := Mix (H, Context.Fingerprint + 1);
      return H;
   end Context_Fingerprint;

   function Semantic_Fingerprint (Info : Cross_Unit_Semantic_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Length (Info.Normalized_Source_Unit_Name) + 1);
      H := Mix (H, Length (Info.Normalized_Target_Unit_Name) + 1);
      H := Mix (H, Length (Info.Normalized_Lookup_Name) + 1);
      H := Mix (H, CU.Cross_Unit_Link_Status'Pos (Info.Dependency_Status) + 1);
      H := Mix (H, LU.Cross_Unit_Lookup_Status'Pos (Info.Lookup_Status) + 1);
      H := Mix (H, AL.Assignment_Legality_Status'Pos (Info.Linked_Assignment_Status) + 1);
      H := Mix (H, RL.Return_Legality_Status'Pos (Info.Linked_Return_Status) + 1);
      H := Mix (H, EL.Semantic_Legality_Status'Pos (Info.Linked_Expression_Status) + 1);
      H := Mix (H, FL.Flow_Legality_Status'Pos (Info.Linked_Flow_Status) + 1);
      H := Mix (H, TL.Tasking_Legality_Status'Pos (Info.Linked_Tasking_Status) + 1);
      H := Mix (H, TD.Tagged_Legality_Status'Pos (Info.Linked_Tagged_Status) + 1);
      H := Mix (H, GI.Instance_Legality_Status'Pos (Info.Linked_Instance_Status) + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Semantic_Fingerprint;

   function Is_Assignment_Ok (Status : AL.Assignment_Legality_Status) return Boolean is
   begin
      return Status in AL.Assignment_Legality_Compatible |
        AL.Assignment_Legality_Class_Wide_Compatible |
        AL.Assignment_Legality_Static_Range_Compatible;
   end Is_Assignment_Ok;

   function Is_Return_Ok (Status : RL.Return_Legality_Status) return Boolean is
   begin
      return Status in RL.Return_Legality_Procedure_Return_Compatible |
        RL.Return_Legality_Function_Return_Compatible |
        RL.Return_Legality_Extended_Return_Compatible;
   end Is_Return_Ok;

   function Is_Expression_Ok (Status : EL.Semantic_Legality_Status) return Boolean is
   begin
      return Status in EL.Semantic_Legality_Legal_Conversion |
        EL.Semantic_Legality_Legal_Qualified_Expression |
        EL.Semantic_Legality_Legal_Access_Conversion |
        EL.Semantic_Legality_Legal_Access_Parameter |
        EL.Semantic_Legality_Legal_Allocator |
        EL.Semantic_Legality_Legal_Aggregate |
        EL.Semantic_Legality_Legal_Container_Aggregate |
        EL.Semantic_Legality_Numeric_Conversion |
        EL.Semantic_Legality_Tagged_Conversion |
        EL.Semantic_Legality_Class_Wide_Conversion |
        EL.Semantic_Legality_Static_Range_Compatible;
   end Is_Expression_Ok;

   function Is_Flow_Ok (Status : FL.Flow_Legality_Status) return Boolean is
   begin
      return Status in FL.Flow_Legality_Legal_Boolean_Condition |
        FL.Flow_Legality_Legal_Case_Statement |
        FL.Flow_Legality_Legal_Exit |
        FL.Flow_Legality_Legal_Goto |
        FL.Flow_Legality_Legal_Label |
        FL.Flow_Legality_Legal_Exception_Handler |
        FL.Flow_Legality_Legal_Raise |
        FL.Flow_Legality_Legal_Select |
        FL.Flow_Legality_Legal_Accept |
        FL.Flow_Legality_Legal_Requeue |
        FL.Flow_Legality_Legal_Return_Path;
   end Is_Flow_Ok;

   function Is_Tasking_Ok (Status : TL.Tasking_Legality_Status) return Boolean is
   begin
      return Status in TL.Tasking_Legality_Legal_Task_Type |
        TL.Tasking_Legality_Legal_Task_Body |
        TL.Tasking_Legality_Legal_Protected_Type |
        TL.Tasking_Legality_Legal_Protected_Body |
        TL.Tasking_Legality_Legal_Entry_Declaration |
        TL.Tasking_Legality_Legal_Entry_Body |
        TL.Tasking_Legality_Legal_Entry_Family |
        TL.Tasking_Legality_Legal_Accept |
        TL.Tasking_Legality_Legal_Requeue |
        TL.Tasking_Legality_Legal_Protected_Function |
        TL.Tasking_Legality_Legal_Protected_Procedure |
        TL.Tasking_Legality_Legal_Protected_Entry |
        TL.Tasking_Legality_Legal_Select;
   end Is_Tasking_Ok;

   function Is_Tagged_Ok (Status : TD.Tagged_Legality_Status) return Boolean is
   begin
      return Status in TD.Tagged_Legality_Legal_Derivation |
        TD.Tagged_Legality_Legal_Private_Extension |
        TD.Tagged_Legality_Legal_Interface_Derivation |
        TD.Tagged_Legality_Legal_Primitive_Operation |
        TD.Tagged_Legality_Legal_Override |
        TD.Tagged_Legality_Legal_Abstract_Type |
        TD.Tagged_Legality_Legal_Dispatching_Call |
        TD.Tagged_Legality_Legal_Class_Wide_Conversion;
   end Is_Tagged_Ok;

   function Is_Instance_Ok (Status : GI.Instance_Legality_Status) return Boolean is
   begin
      return Status in GI.Instance_Legality_Legal_Instance |
        GI.Instance_Legality_Legal_Body_Substitution |
        GI.Instance_Legality_Legal_Default_Substitution |
        GI.Instance_Legality_Legal_Formal_Package_Substitution |
        GI.Instance_Legality_Legal_Boxed_Formal_Package |
        GI.Instance_Legality_Legal_Instance_Freezing |
        GI.Instance_Legality_Legal_Representation_Item;
   end Is_Instance_Ok;

   function Lookup_Status_For
     (Context : Cross_Unit_Semantic_Context_Info;
      Lookup  : LU.Cross_Unit_Lookup_Model) return LU.Cross_Unit_Lookup_Status
   is
      Feed_Item : LU.Cross_Unit_Lookup_Entry;
   begin
      if not Context.Requires_Cross_Unit_Lookup then
         return Context.Lookup_Status;
      elsif Length (Context.Normalized_Lookup_Name) = 0 then
         return Context.Lookup_Status;
      end if;

      Feed_Item := LU.Lookup_Name (Lookup, To_String (Context.Normalized_Lookup_Name));
      if Feed_Item.Id /= LU.No_Cross_Unit_Lookup then
         return Feed_Item.Status;
      else
         return Context.Lookup_Status;
      end if;
   end Lookup_Status_For;

   function Dependency_Error (Status : CU.Cross_Unit_Link_Status) return Cross_Unit_Semantic_Status is
   begin
      case Status is
         when CU.Cross_Unit_Link_Resolved =>
            return Cross_Unit_Semantic_Closed;
         when CU.Cross_Unit_Link_Missing =>
            return Cross_Unit_Semantic_Missing_Dependency;
         when CU.Cross_Unit_Link_Ambiguous =>
            return Cross_Unit_Semantic_Ambiguous_Dependency;
         when CU.Cross_Unit_Link_Overflow =>
            return Cross_Unit_Semantic_Dependency_Overflow;
         when CU.Cross_Unit_Link_Not_Applicable =>
            return Cross_Unit_Semantic_Local_Only;
      end case;
   end Dependency_Error;

   function Lookup_Error (Status : LU.Cross_Unit_Lookup_Status) return Cross_Unit_Semantic_Status is
   begin
      case Status is
         when LU.Cross_Unit_Lookup_Local_Found =>
            return Cross_Unit_Semantic_Local_Only;
         when LU.Cross_Unit_Lookup_With_Visible =>
            return Cross_Unit_Semantic_With_Visible;
         when LU.Cross_Unit_Lookup_Use_Visible =>
            return Cross_Unit_Semantic_Use_Visible;
         when LU.Cross_Unit_Lookup_Limited_Incomplete_View =>
            return Cross_Unit_Semantic_Limited_View_Barrier;
         when LU.Cross_Unit_Lookup_Private_View =>
            return Cross_Unit_Semantic_Private_View_Barrier;
         when LU.Cross_Unit_Lookup_Missing | LU.Cross_Unit_Lookup_Not_Found =>
            return Cross_Unit_Semantic_Missing_Lookup;
         when LU.Cross_Unit_Lookup_Ambiguous | LU.Cross_Unit_Lookup_Local_Ambiguous =>
            return Cross_Unit_Semantic_Ambiguous_Lookup;
         when LU.Cross_Unit_Lookup_Overflow =>
            return Cross_Unit_Semantic_Lookup_Overflow;
      end case;
   end Lookup_Error;

   function Message_For (Status : Cross_Unit_Semantic_Status) return String is
   begin
      case Status is
         when Cross_Unit_Semantic_Closed => return "cross-unit semantic dependency is closed";
         when Cross_Unit_Semantic_Local_Only => return "semantic context is local-only";
         when Cross_Unit_Semantic_With_Visible => return "semantic dependency is visible through with clause";
         when Cross_Unit_Semantic_Use_Visible => return "semantic dependency is visible through use clause";
         when Cross_Unit_Semantic_Limited_View_Barrier => return "cross-unit semantic closure stops at a limited view";
         when Cross_Unit_Semantic_Private_View_Barrier => return "cross-unit semantic closure stops at a private view";
         when Cross_Unit_Semantic_Missing_Dependency => return "cross-unit semantic dependency is missing";
         when Cross_Unit_Semantic_Ambiguous_Dependency => return "cross-unit semantic dependency is ambiguous";
         when Cross_Unit_Semantic_Dependency_Overflow => return "cross-unit semantic dependency overflowed bounded resolution";
         when Cross_Unit_Semantic_Missing_Lookup => return "cross-unit semantic lookup is missing";
         when Cross_Unit_Semantic_Ambiguous_Lookup => return "cross-unit semantic lookup is ambiguous";
         when Cross_Unit_Semantic_Lookup_Overflow => return "cross-unit semantic lookup overflowed bounded resolution";
         when Cross_Unit_Semantic_Assignment_Error => return "assignment legality blocks cross-unit semantic closure";
         when Cross_Unit_Semantic_Return_Error => return "return legality blocks cross-unit semantic closure";
         when Cross_Unit_Semantic_Expression_Error => return "expression legality blocks cross-unit semantic closure";
         when Cross_Unit_Semantic_Control_Flow_Error => return "control-flow legality blocks cross-unit semantic closure";
         when Cross_Unit_Semantic_Tasking_Error => return "tasking/protected legality blocks cross-unit semantic closure";
         when Cross_Unit_Semantic_Tagged_Derived_Error => return "tagged/derived legality blocks cross-unit semantic closure";
         when Cross_Unit_Semantic_Generic_Instance_Error => return "generic-instance legality blocks cross-unit semantic closure";
         when Cross_Unit_Semantic_Representation_Error => return "representation legality blocks cross-unit semantic closure";
         when others => return "cross-unit semantic closure is indeterminate";
      end case;
   end Message_For;

   function Is_Dependency_Error (Status : Cross_Unit_Semantic_Status) return Boolean is
   begin
      return Status in Cross_Unit_Semantic_Missing_Dependency |
        Cross_Unit_Semantic_Ambiguous_Dependency |
        Cross_Unit_Semantic_Dependency_Overflow;
   end Is_Dependency_Error;

   function Is_Lookup_Error (Status : Cross_Unit_Semantic_Status) return Boolean is
   begin
      return Status in Cross_Unit_Semantic_Missing_Lookup |
        Cross_Unit_Semantic_Ambiguous_Lookup |
        Cross_Unit_Semantic_Lookup_Overflow;
   end Is_Lookup_Error;

   function Is_Linked_Error (Status : Cross_Unit_Semantic_Status) return Boolean is
   begin
      return Status in Cross_Unit_Semantic_Assignment_Error |
        Cross_Unit_Semantic_Return_Error |
        Cross_Unit_Semantic_Expression_Error |
        Cross_Unit_Semantic_Control_Flow_Error |
        Cross_Unit_Semantic_Tasking_Error |
        Cross_Unit_Semantic_Tagged_Derived_Error |
        Cross_Unit_Semantic_Generic_Instance_Error |
        Cross_Unit_Semantic_Representation_Error;
   end Is_Linked_Error;

   function Is_Warning (Status : Cross_Unit_Semantic_Status) return Boolean is
   begin
      return Status in Cross_Unit_Semantic_Local_Only |
        Cross_Unit_Semantic_Indeterminate;
   end Is_Warning;

   function Is_Error (Status : Cross_Unit_Semantic_Status) return Boolean is
   begin
      return Status in Cross_Unit_Semantic_Limited_View_Barrier |
        Cross_Unit_Semantic_Private_View_Barrier |
        Cross_Unit_Semantic_Missing_Dependency |
        Cross_Unit_Semantic_Ambiguous_Dependency |
        Cross_Unit_Semantic_Dependency_Overflow |
        Cross_Unit_Semantic_Missing_Lookup |
        Cross_Unit_Semantic_Ambiguous_Lookup |
        Cross_Unit_Semantic_Lookup_Overflow |
        Cross_Unit_Semantic_Assignment_Error |
        Cross_Unit_Semantic_Return_Error |
        Cross_Unit_Semantic_Expression_Error |
        Cross_Unit_Semantic_Control_Flow_Error |
        Cross_Unit_Semantic_Tasking_Error |
        Cross_Unit_Semantic_Tagged_Derived_Error |
        Cross_Unit_Semantic_Generic_Instance_Error |
        Cross_Unit_Semantic_Representation_Error;
   end Is_Error;

   procedure Append (Model : in out Cross_Unit_Semantic_Model; Info : Cross_Unit_Semantic_Info) is
   begin
      Model.Entries.Append (Info);

      case Info.Status is
         when Cross_Unit_Semantic_Closed => Model.Closed_Total := Model.Closed_Total + 1;
         when Cross_Unit_Semantic_Local_Only => Model.Local_Only_Total := Model.Local_Only_Total + 1;
         when Cross_Unit_Semantic_With_Visible | Cross_Unit_Semantic_Use_Visible =>
            Model.Cross_Unit_Visible_Total := Model.Cross_Unit_Visible_Total + 1;
         when Cross_Unit_Semantic_Limited_View_Barrier =>
            Model.Limited_View_Barrier_Total := Model.Limited_View_Barrier_Total + 1;
         when Cross_Unit_Semantic_Private_View_Barrier =>
            Model.Private_View_Barrier_Total := Model.Private_View_Barrier_Total + 1;
         when others => null;
      end case;

      if Is_Dependency_Error (Info.Status) then
         Model.Dependency_Error_Total := Model.Dependency_Error_Total + 1;
      end if;
      if Is_Lookup_Error (Info.Status) then
         Model.Lookup_Error_Total := Model.Lookup_Error_Total + 1;
      end if;
      if Is_Linked_Error (Info.Status) then
         Model.Linked_Semantic_Error_Total := Model.Linked_Semantic_Error_Total + 1;
      end if;
      if Is_Error (Info.Status) then
         Model.Error_Total := Model.Error_Total + 1;
      elsif Is_Warning (Info.Status) then
         Model.Warning_Total := Model.Warning_Total + 1;
      end if;

      Model.Model_Fingerprint := Mix (Model.Model_Fingerprint + 1, Info.Fingerprint + 1);
   end Append;

   procedure Clear (Model : in out Cross_Unit_Semantic_Context_Model) is
   begin
      Model.Entries.Clear;
      Model.Model_Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Cross_Unit_Semantic_Context_Model;
      Context : Cross_Unit_Semantic_Context_Info)
   is
      Item : Cross_Unit_Semantic_Context_Info := Context;
   begin
      if Length (Item.Normalized_Source_Unit_Name) = 0 then
         Item.Normalized_Source_Unit_Name := Normalize (Item.Source_Unit_Name);
      end if;
      if Length (Item.Normalized_Target_Unit_Name) = 0 then
         Item.Normalized_Target_Unit_Name := Normalize (Item.Target_Unit_Name);
      end if;
      if Length (Item.Normalized_Lookup_Name) = 0 then
         Item.Normalized_Lookup_Name := Normalize (Item.Lookup_Name);
      end if;
      if Item.Fingerprint = 0 then
         Item.Fingerprint := Context_Fingerprint (Item);
      end if;
      Model.Entries.Append (Item);
      Model.Model_Fingerprint := Mix (Model.Model_Fingerprint + 1, Item.Fingerprint + 1);
   end Add_Context;

   function Context_Count (Model : Cross_Unit_Semantic_Context_Model) return Natural is
   begin
      return Natural (Model.Entries.Length);
   end Context_Count;

   function Context_At
     (Model : Cross_Unit_Semantic_Context_Model;
      Index : Positive) return Cross_Unit_Semantic_Context_Info is
   begin
      return Model.Entries.Element (Index);
   end Context_At;

   function Fingerprint (Model : Cross_Unit_Semantic_Context_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

   function Classify
     (Context    : Cross_Unit_Semantic_Context_Info;
      Lookup_Status : LU.Cross_Unit_Lookup_Status;
      Assignment_Status : AL.Assignment_Legality_Status;
      Return_Status : RL.Return_Legality_Status;
      Expression_Status : EL.Semantic_Legality_Status;
      Flow_Status : FL.Flow_Legality_Status;
      Tasking_Status : TL.Tasking_Legality_Status;
      Tagged_Status : TD.Tagged_Legality_Status;
      Instance_Status : GI.Instance_Legality_Status) return Cross_Unit_Semantic_Status
   is
      D_Status : Cross_Unit_Semantic_Status;
      L_Status : Cross_Unit_Semantic_Status;
   begin
      if Context.Requires_Cross_Unit_Dependency then
         D_Status := Dependency_Error (Context.Dependency_Status);
         if D_Status in Cross_Unit_Semantic_Missing_Dependency |
           Cross_Unit_Semantic_Ambiguous_Dependency |
           Cross_Unit_Semantic_Dependency_Overflow
         then
            return D_Status;
         end if;
      end if;

      if Context.Requires_Cross_Unit_Lookup then
         L_Status := Lookup_Error (Lookup_Status);
         if L_Status in Cross_Unit_Semantic_Limited_View_Barrier |
           Cross_Unit_Semantic_Private_View_Barrier |
           Cross_Unit_Semantic_Missing_Lookup |
           Cross_Unit_Semantic_Ambiguous_Lookup |
           Cross_Unit_Semantic_Lookup_Overflow
         then
            return L_Status;
         end if;
      end if;

      if Context.Linked_Assignment /= AL.No_Assignment_Context
        and then not Is_Assignment_Ok (Assignment_Status)
      then
         return Cross_Unit_Semantic_Assignment_Error;
      elsif Context.Linked_Return /= RL.No_Return_Context
        and then not Is_Return_Ok (Return_Status)
      then
         return Cross_Unit_Semantic_Return_Error;
      elsif Context.Linked_Expression /= EL.No_Semantic_Context
        and then not Is_Expression_Ok (Expression_Status)
      then
         return Cross_Unit_Semantic_Expression_Error;
      elsif Context.Linked_Flow /= FL.No_Flow_Context
        and then not Is_Flow_Ok (Flow_Status)
      then
         return Cross_Unit_Semantic_Control_Flow_Error;
      elsif Context.Linked_Tasking /= TL.No_Tasking_Context
        and then not Is_Tasking_Ok (Tasking_Status)
      then
         return Cross_Unit_Semantic_Tasking_Error;
      elsif Context.Linked_Tagged /= TD.No_Tagged_Context
        and then not Is_Tagged_Ok (Tagged_Status)
      then
         return Cross_Unit_Semantic_Tagged_Derived_Error;
      elsif Context.Linked_Instance /= GI.No_Instance_Context
        and then not Is_Instance_Ok (Instance_Status)
      then
         if Instance_Status in GI.Instance_Legality_Representation_After_Instance_Freezing |
           GI.Instance_Legality_Representation_Target_Unresolved |
           GI.Instance_Legality_Representation_Target_Ambiguous |
           GI.Instance_Legality_Representation_Target_Kind_Mismatch |
           GI.Instance_Legality_Representation_Static_Error |
           GI.Instance_Legality_Representation_Profile_Error |
           GI.Instance_Legality_Representation_Operational_Error
         then
            return Cross_Unit_Semantic_Representation_Error;
         else
            return Cross_Unit_Semantic_Generic_Instance_Error;
         end if;
      end if;

      if Context.Requires_Cross_Unit_Lookup then
         return Lookup_Error (Lookup_Status);
      elsif Context.Requires_Cross_Unit_Dependency then
         return Cross_Unit_Semantic_Closed;
      else
         return Cross_Unit_Semantic_Local_Only;
      end if;
   end Classify;

   function Build
     (Contexts    : Cross_Unit_Semantic_Context_Model;
      Closure     : CU.Cross_Unit_Closure_Model;
      Lookup      : LU.Cross_Unit_Lookup_Model;
      Assignments : AL.Assignment_Legality_Model;
      Returns     : RL.Return_Legality_Model;
      Expressions : EL.Semantic_Legality_Model;
      Flow        : FL.Flow_Legality_Model;
      Tasking     : TL.Tasking_Legality_Model;
      Tagged_Model      : TD.Tagged_Legality_Model;
      Instances   : GI.Instance_Legality_Model)
      return Cross_Unit_Semantic_Model
   is
      pragma Unreferenced (Closure);
      Model : Cross_Unit_Semantic_Model;
   begin
      for Index in 1 .. Context_Count (Contexts) loop
         declare
            Context : constant Cross_Unit_Semantic_Context_Info := Context_At (Contexts, Index);
            Info    : Cross_Unit_Semantic_Info;
            A_Info  : AL.Assignment_Legality_Info;
            R_Info  : RL.Return_Legality_Info;
            E_Info  : EL.Semantic_Legality_Info;
            F_Info  : FL.Flow_Legality_Info;
            T_Info  : TL.Tasking_Legality_Info;
            D_Info  : TD.Tagged_Legality_Info;
            I_Info  : GI.Instance_Legality_Info;
         begin
            Info.Id := Cross_Unit_Semantic_Id (Index);
            Info.Context := Context.Id;
            Info.Kind := Context.Kind;
            Info.Node := Context.Node;
            Info.Normalized_Source_Unit_Name := Context.Normalized_Source_Unit_Name;
            Info.Normalized_Target_Unit_Name := Context.Normalized_Target_Unit_Name;
            Info.Normalized_Lookup_Name := Context.Normalized_Lookup_Name;
            Info.Dependency_Status := Context.Dependency_Status;
            Info.Lookup_Status := Lookup_Status_For (Context, Lookup);
            Info.Start_Line := Context.Start_Line;
            Info.Start_Column := Context.Start_Column;
            Info.End_Line := Context.End_Line;
            Info.End_Column := Context.End_Column;
            Info.Source_Fingerprint := Context.Fingerprint;

            A_Info := AL.First_For_Context (Assignments, Context.Linked_Assignment);
            R_Info := RL.First_For_Context (Returns, Context.Linked_Return);
            E_Info := EL.First_For_Context (Expressions, Context.Linked_Expression);
            F_Info := FL.First_For_Context (Flow, Context.Linked_Flow);
            T_Info := TL.First_For_Context (Tasking, Context.Linked_Tasking);
            D_Info := TD.First_For_Context (Tagged_Model, Context.Linked_Tagged);
            I_Info := GI.First_For_Context (Instances, Context.Linked_Instance);

            Info.Linked_Assignment_Status := A_Info.Status;
            Info.Linked_Return_Status := R_Info.Status;
            Info.Linked_Expression_Status := E_Info.Status;
            Info.Linked_Flow_Status := F_Info.Status;
            Info.Linked_Tasking_Status := T_Info.Status;
            Info.Linked_Tagged_Status := D_Info.Status;
            Info.Linked_Instance_Status := I_Info.Status;

            Info.Status := Classify
              (Context, Info.Lookup_Status,
               Info.Linked_Assignment_Status,
               Info.Linked_Return_Status,
               Info.Linked_Expression_Status,
               Info.Linked_Flow_Status,
               Info.Linked_Tasking_Status,
               Info.Linked_Tagged_Status,
               Info.Linked_Instance_Status);
            Info.Message := To_Unbounded_String (Message_For (Info.Status));
            Info.Detail := To_Unbounded_String ("cross-unit semantic closure across compiler-grade legality layers");
            Info.Fingerprint := Semantic_Fingerprint (Info);
            Append (Model, Info);
         end;
      end loop;

      Model.Model_Fingerprint := Mix (Model.Model_Fingerprint + 1, Contexts.Model_Fingerprint + 1);
      return Model;
   end Build;

   function Build_Local_Contexts_From_Legality
     (Source_Unit_Name : String;
      Assignments : AL.Assignment_Legality_Model;
      Returns     : RL.Return_Legality_Model;
      Expressions : EL.Semantic_Legality_Model;
      Flow        : FL.Flow_Legality_Model;
      Tasking     : TL.Tasking_Legality_Model;
      Tagged_Model      : TD.Tagged_Legality_Model;
      Instances   : GI.Instance_Legality_Model)
      return Cross_Unit_Semantic_Context_Model
   is
      Model  : Cross_Unit_Semantic_Context_Model;
      Next   : Cross_Unit_Semantic_Context_Id := No_Cross_Unit_Semantic_Context;
      Source : constant Unbounded_String := To_Unbounded_String (Source_Unit_Name);

      procedure Add (Context : Cross_Unit_Semantic_Context_Info) is
         Item : Cross_Unit_Semantic_Context_Info := Context;
      begin
         Next := Next + 1;
         Item.Id := Next;
         Item.Source_Unit_Name := Source;
         Add_Context (Model, Item);
      end Add;
   begin
      for Index in 1 .. AL.Legality_Count (Assignments) loop
         declare
            Info    : constant AL.Assignment_Legality_Info :=
              AL.Legality_At (Assignments, Index);
            Context : Cross_Unit_Semantic_Context_Info;
         begin
            Context.Kind := Cross_Unit_Semantic_Assignment;
            Context.Node :=
              (if Info.Target_Node /= Editor.Ada_Syntax_Tree.No_Node
               then Info.Target_Node
               else Info.Source_Node);
            Context.Linked_Assignment := Info.Context;
            Context.Start_Line := Info.Start_Line;
            Context.Start_Column := Info.Start_Column;
            Context.End_Line := Info.End_Line;
            Context.End_Column := Info.End_Column;
            Context.Fingerprint := Info.Fingerprint;
            Add (Context);
         end;
      end loop;

      for Index in 1 .. RL.Legality_Count (Returns) loop
         declare
            Info    : constant RL.Return_Legality_Info := RL.Legality_At (Returns, Index);
            Context : Cross_Unit_Semantic_Context_Info;
         begin
            Context.Kind := Cross_Unit_Semantic_Return;
            Context.Node := Info.Return_Node;
            Context.Linked_Return := Info.Context;
            Context.Start_Line := Info.Start_Line;
            Context.Start_Column := Info.Start_Column;
            Context.End_Line := Info.End_Line;
            Context.End_Column := Info.End_Column;
            Context.Fingerprint := Info.Fingerprint;
            Add (Context);
         end;
      end loop;

      for Index in 1 .. EL.Legality_Count (Expressions) loop
         declare
            Info    : constant EL.Semantic_Legality_Info :=
              EL.Legality_At (Expressions, Index);
            Context : Cross_Unit_Semantic_Context_Info;
         begin
            Context.Kind := Cross_Unit_Semantic_Expression;
            Context.Node := Info.Node;
            Context.Linked_Expression := Info.Context;
            Context.Start_Line := Info.Start_Line;
            Context.End_Line := Info.End_Line;
            Context.Fingerprint := Info.Fingerprint;
            Add (Context);
         end;
      end loop;

      for Index in 1 .. FL.Legality_Count (Flow) loop
         declare
            Info    : constant FL.Flow_Legality_Info := FL.Legality_At (Flow, Index);
            Context : Cross_Unit_Semantic_Context_Info;
         begin
            Context.Kind := Cross_Unit_Semantic_Control_Flow;
            Context.Node := Info.Node;
            Context.Linked_Flow := Info.Context;
            Context.Start_Line := Info.Start_Line;
            Context.Start_Column := Info.Start_Column;
            Context.End_Line := Info.End_Line;
            Context.End_Column := Info.End_Column;
            Context.Fingerprint := Info.Fingerprint;
            Add (Context);
         end;
      end loop;

      for Index in 1 .. TL.Legality_Count (Tasking) loop
         declare
            Info    : constant TL.Tasking_Legality_Info :=
              TL.Legality_At (Tasking, Index);
            Context : Cross_Unit_Semantic_Context_Info;
         begin
            Context.Kind := Cross_Unit_Semantic_Tasking_Protected;
            Context.Node := Info.Node;
            Context.Linked_Tasking := Info.Context;
            Context.Start_Line := Info.Start_Line;
            Context.Start_Column := Info.Start_Column;
            Context.End_Line := Info.End_Line;
            Context.End_Column := Info.End_Column;
            Context.Fingerprint := Info.Fingerprint;
            Add (Context);
         end;
      end loop;

      for Index in 1 .. TD.Legality_Count (Tagged_Model) loop
         declare
            Info    : constant TD.Tagged_Legality_Info :=
              TD.Legality_At (Tagged_Model, Index);
            Context : Cross_Unit_Semantic_Context_Info;
         begin
            Context.Kind := Cross_Unit_Semantic_Tagged_Derived;
            Context.Node := Info.Node;
            Context.Linked_Tagged := Info.Context;
            Context.Start_Line := Info.Start_Line;
            Context.Start_Column := Info.Start_Column;
            Context.End_Line := Info.End_Line;
            Context.End_Column := Info.End_Column;
            Context.Fingerprint := Info.Fingerprint;
            Add (Context);
         end;
      end loop;

      for Index in 1 .. GI.Legality_Count (Instances) loop
         declare
            Info    : constant GI.Instance_Legality_Info :=
              GI.Legality_At (Instances, Index);
            Context : Cross_Unit_Semantic_Context_Info;
         begin
            Context.Kind := Cross_Unit_Semantic_Generic_Instance;
            Context.Node := Info.Node;
            Context.Linked_Instance := Info.Context;
            Context.Start_Line := 1;
            Context.End_Line := 1;
            Context.Fingerprint := Info.Fingerprint;
            Add (Context);
         end;
      end loop;

      return Model;
   end Build_Local_Contexts_From_Legality;

   function Semantic_Count (Model : Cross_Unit_Semantic_Model) return Natural is
   begin
      return Natural (Model.Entries.Length);
   end Semantic_Count;

   function Semantic_At
     (Model : Cross_Unit_Semantic_Model;
      Index : Positive) return Cross_Unit_Semantic_Info is
   begin
      return Model.Entries.Element (Index);
   end Semantic_At;

   function First_For_Context
     (Model   : Cross_Unit_Semantic_Model;
      Context : Cross_Unit_Semantic_Context_Id) return Cross_Unit_Semantic_Info is
   begin
      for Item of Model.Entries loop
         if Item.Context = Context then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Context;

   function First_For_Node
     (Model : Cross_Unit_Semantic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Cross_Unit_Semantic_Info is
   begin
      for Item of Model.Entries loop
         if Item.Node = Node then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Cross_Unit_Semantic_Model;
      Status : Cross_Unit_Semantic_Status) return Cross_Unit_Semantic_Result_Set
   is
      Results : Cross_Unit_Semantic_Result_Set;
   begin
      for Item of Model.Entries loop
         if Item.Status = Status then
            Results.Entries.Append (Item);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Cross_Unit_Semantic_Model;
      Kind  : Cross_Unit_Semantic_Context_Kind) return Cross_Unit_Semantic_Result_Set
   is
      Results : Cross_Unit_Semantic_Result_Set;
   begin
      for Item of Model.Entries loop
         if Item.Kind = Kind then
            Results.Entries.Append (Item);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Source_Unit
     (Model : Cross_Unit_Semantic_Model;
      Name  : Unbounded_String) return Cross_Unit_Semantic_Result_Set
   is
      Results : Cross_Unit_Semantic_Result_Set;
      Normal  : constant Unbounded_String := Normalize (Name);
   begin
      for Item of Model.Entries loop
         if Item.Normalized_Source_Unit_Name = Normal then
            Results.Entries.Append (Item);
         end if;
      end loop;
      return Results;
   end Rows_For_Source_Unit;

   function Rows_For_Target_Unit
     (Model : Cross_Unit_Semantic_Model;
      Name  : Unbounded_String) return Cross_Unit_Semantic_Result_Set
   is
      Results : Cross_Unit_Semantic_Result_Set;
      Normal  : constant Unbounded_String := Normalize (Name);
   begin
      for Item of Model.Entries loop
         if Item.Normalized_Target_Unit_Name = Normal then
            Results.Entries.Append (Item);
         end if;
      end loop;
      return Results;
   end Rows_For_Target_Unit;

   function Rows_For_Lookup_Name
     (Model : Cross_Unit_Semantic_Model;
      Name  : Unbounded_String) return Cross_Unit_Semantic_Result_Set
   is
      Results : Cross_Unit_Semantic_Result_Set;
      Normal  : constant Unbounded_String := Normalize (Name);
   begin
      for Item of Model.Entries loop
         if Item.Normalized_Lookup_Name = Normal then
            Results.Entries.Append (Item);
         end if;
      end loop;
      return Results;
   end Rows_For_Lookup_Name;

   function Result_Count (Results : Cross_Unit_Semantic_Result_Set) return Natural is
   begin
      return Natural (Results.Entries.Length);
   end Result_Count;

   function Result_At
     (Results : Cross_Unit_Semantic_Result_Set;
      Index   : Positive) return Cross_Unit_Semantic_Info is
   begin
      return Results.Entries.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Cross_Unit_Semantic_Model;
      Status : Cross_Unit_Semantic_Status) return Natural
   is
      Total : Natural := 0;
   begin
      for Item of Model.Entries loop
         if Item.Status = Status then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Status;

   function Count_Kind
     (Model : Cross_Unit_Semantic_Model;
      Kind  : Cross_Unit_Semantic_Context_Kind) return Natural
   is
      Total : Natural := 0;
   begin
      for Item of Model.Entries loop
         if Item.Kind = Kind then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_Kind;

   function Closed_Count (Model : Cross_Unit_Semantic_Model) return Natural is
   begin
      return Model.Closed_Total;
   end Closed_Count;

   function Local_Only_Count (Model : Cross_Unit_Semantic_Model) return Natural is
   begin
      return Model.Local_Only_Total;
   end Local_Only_Count;

   function Cross_Unit_Visible_Count (Model : Cross_Unit_Semantic_Model) return Natural is
   begin
      return Model.Cross_Unit_Visible_Total;
   end Cross_Unit_Visible_Count;

   function Limited_View_Barrier_Count (Model : Cross_Unit_Semantic_Model) return Natural is
   begin
      return Model.Limited_View_Barrier_Total;
   end Limited_View_Barrier_Count;

   function Private_View_Barrier_Count (Model : Cross_Unit_Semantic_Model) return Natural is
   begin
      return Model.Private_View_Barrier_Total;
   end Private_View_Barrier_Count;

   function Dependency_Error_Count (Model : Cross_Unit_Semantic_Model) return Natural is
   begin
      return Model.Dependency_Error_Total;
   end Dependency_Error_Count;

   function Lookup_Error_Count (Model : Cross_Unit_Semantic_Model) return Natural is
   begin
      return Model.Lookup_Error_Total;
   end Lookup_Error_Count;

   function Linked_Semantic_Error_Count (Model : Cross_Unit_Semantic_Model) return Natural is
   begin
      return Model.Linked_Semantic_Error_Total;
   end Linked_Semantic_Error_Count;

   function Error_Count (Model : Cross_Unit_Semantic_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Cross_Unit_Semantic_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Fingerprint (Model : Cross_Unit_Semantic_Model) return Natural is
   begin
      return Model.Model_Fingerprint;
   end Fingerprint;

end Editor.Ada_Cross_Unit_Semantic_Closure;
