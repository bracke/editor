with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Wide_Semantic_Legality_Diagnostics is

   pragma Suppress (Overflow_Check);
   use type Editor.Ada_Assignment_Legality.Assignment_Legality_Status;
   use type Editor.Ada_Return_Legality.Return_Legality_Status;
   use type Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Status;
   use type Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Status;
   use type Editor.Ada_Control_Flow_Legality.Flow_Legality_Status;
   use type Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Status;
   use type Editor.Ada_Tagged_Derived_Legality.Tagged_Legality_Status;
   use type Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   package AL renames Editor.Ada_Assignment_Legality;
   package RL renames Editor.Ada_Return_Legality;
   package EL renames Editor.Ada_Conversion_Access_Aggregate_Legality;
   package FL renames Editor.Ada_Control_Flow_Legality;
   package TL renames Editor.Ada_Tasking_Protected_Legality;
   package TD renames Editor.Ada_Tagged_Derived_Legality;
   package GI renames Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
   package CU renames Editor.Ada_Cross_Unit_Semantic_Closure;

   function Mix (Left, Right : Natural) return Natural is
      Modulus : constant Long_Long_Integer := 2_147_483_647;
      L : constant Long_Long_Integer :=
        Long_Long_Integer (Left mod Natural (Modulus));
      R : constant Long_Long_Integer :=
        Long_Long_Integer (Right mod Natural (Modulus));
      Hash : constant Long_Long_Integer :=
        (L * 1_315_423_911 + R * 2_654_435_761 + 197) mod Modulus;
   begin
      return Natural (Hash);
   end Mix;

   function Family_Slot (Family : Wide_Semantic_Diagnostic_Family) return Natural is
   begin
      return Wide_Semantic_Diagnostic_Family'Pos (Family) + 1;
   end Family_Slot;

   function Kind_Slot (Kind : Wide_Semantic_Diagnostic_Kind) return Natural is
   begin
      return Wide_Semantic_Diagnostic_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Severity_Slot (Severity : Wide_Semantic_Diagnostic_Severity) return Natural is
   begin
      return Wide_Semantic_Diagnostic_Severity'Pos (Severity) + 1;
   end Severity_Slot;

   function Diagnostic_Fingerprint (Info : Wide_Semantic_Diagnostic_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Family_Slot (Info.Family));
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Severity_Slot (Info.Severity));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, AL.Assignment_Legality_Status'Pos (Info.Assignment_Status) + 1);
      H := Mix (H, RL.Return_Legality_Status'Pos (Info.Return_Status) + 1);
      H := Mix (H, EL.Semantic_Legality_Status'Pos (Info.Expression_Status) + 1);
      H := Mix (H, FL.Flow_Legality_Status'Pos (Info.Flow_Status) + 1);
      H := Mix (H, TL.Tasking_Legality_Status'Pos (Info.Tasking_Status) + 1);
      H := Mix (H, TD.Tagged_Legality_Status'Pos (Info.Tagged_Status) + 1);
      H := Mix (H, GI.Instance_Legality_Status'Pos (Info.Instance_Status) + 1);
      H := Mix (H, CU.Cross_Unit_Semantic_Status'Pos (Info.Cross_Unit_Status) + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.Start_Column);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.End_Column);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Diagnostic_Fingerprint;

   function Is_Assignment_Legal (Status : AL.Assignment_Legality_Status) return Boolean is
   begin
      return Status in AL.Assignment_Legality_Compatible |
        AL.Assignment_Legality_Class_Wide_Compatible |
        AL.Assignment_Legality_Static_Range_Compatible;
   end Is_Assignment_Legal;

   function Is_Return_Legal (Status : RL.Return_Legality_Status) return Boolean is
   begin
      return Status in RL.Return_Legality_Procedure_Return_Compatible |
        RL.Return_Legality_Function_Return_Compatible |
        RL.Return_Legality_Extended_Return_Compatible;
   end Is_Return_Legal;

   function Is_Expression_Legal (Status : EL.Semantic_Legality_Status) return Boolean is
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
   end Is_Expression_Legal;

   function Is_Flow_Legal (Status : FL.Flow_Legality_Status) return Boolean is
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
   end Is_Flow_Legal;

   function Is_Tasking_Legal (Status : TL.Tasking_Legality_Status) return Boolean is
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
   end Is_Tasking_Legal;

   function Is_Tagged_Legal (Status : TD.Tagged_Legality_Status) return Boolean is
   begin
      return Status in TD.Tagged_Legality_Legal_Derivation |
        TD.Tagged_Legality_Legal_Private_Extension |
        TD.Tagged_Legality_Legal_Interface_Derivation |
        TD.Tagged_Legality_Legal_Primitive_Operation |
        TD.Tagged_Legality_Legal_Override |
        TD.Tagged_Legality_Legal_Abstract_Type |
        TD.Tagged_Legality_Legal_Dispatching_Call |
        TD.Tagged_Legality_Legal_Class_Wide_Conversion;
   end Is_Tagged_Legal;

   function Is_Instance_Legal (Status : GI.Instance_Legality_Status) return Boolean is
   begin
      return Status in GI.Instance_Legality_Legal_Instance |
        GI.Instance_Legality_Legal_Body_Substitution |
        GI.Instance_Legality_Legal_Default_Substitution |
        GI.Instance_Legality_Legal_Formal_Package_Substitution |
        GI.Instance_Legality_Legal_Boxed_Formal_Package |
        GI.Instance_Legality_Legal_Instance_Freezing |
        GI.Instance_Legality_Legal_Representation_Item;
   end Is_Instance_Legal;

   function Is_Cross_Unit_Legal (Status : CU.Cross_Unit_Semantic_Status) return Boolean is
   begin
      return Status in CU.Cross_Unit_Semantic_Closed |
        CU.Cross_Unit_Semantic_Local_Only |
        CU.Cross_Unit_Semantic_With_Visible |
        CU.Cross_Unit_Semantic_Use_Visible;
   end Is_Cross_Unit_Legal;

   function Is_Unresolved (Status : AL.Assignment_Legality_Status) return Boolean is
   begin
      return Status in AL.Assignment_Legality_Target_Unresolved |
        AL.Assignment_Legality_Source_Unresolved |
        AL.Assignment_Legality_Cross_Unit_Unresolved_View |
        AL.Assignment_Legality_Universal_Numeric_Unresolved;
   end Is_Unresolved;

   function Is_Unresolved (Status : RL.Return_Legality_Status) return Boolean is
   begin
      return Status in RL.Return_Legality_Result_Target_Unresolved |
        RL.Return_Legality_Result_Source_Unresolved |
        RL.Return_Legality_Result_Cross_Unit_Unresolved_View |
        RL.Return_Legality_Result_Universal_Numeric_Unresolved;
   end Is_Unresolved;

   function Is_Unresolved (Status : EL.Semantic_Legality_Status) return Boolean is
   begin
      return Status in EL.Semantic_Legality_Target_Unresolved |
        EL.Semantic_Legality_Operand_Unresolved |
        EL.Semantic_Legality_Cross_Unit_Unresolved_View |
        EL.Semantic_Legality_Universal_Numeric_Unresolved;
   end Is_Unresolved;

   function Severity_For_Unresolved (Unresolved : Boolean) return Wide_Semantic_Diagnostic_Severity is
   begin
      if Unresolved then
         return Wide_Semantic_Diagnostic_Warning;
      else
         return Wide_Semantic_Diagnostic_Error;
      end if;
   end Severity_For_Unresolved;

   function Kind_For_Assignment (Status : AL.Assignment_Legality_Status)
      return Wide_Semantic_Diagnostic_Kind is
   begin
      if Status in AL.Assignment_Legality_Private_View_Barrier |
        AL.Assignment_Legality_Limited_View_Barrier then
         return Wide_Semantic_Diagnostic_View_Barrier;
      elsif Status = AL.Assignment_Legality_Static_Range_Violation then
         return Wide_Semantic_Diagnostic_Static_Range_Error;
      elsif Is_Unresolved (Status) then
         return Wide_Semantic_Diagnostic_Unresolved_Semantic_State;
      elsif Status = AL.Assignment_Legality_Indeterminate then
         return Wide_Semantic_Diagnostic_Indeterminate_State;
      else
         return Wide_Semantic_Diagnostic_Assignment_Legality_Error;
      end if;
   end Kind_For_Assignment;

   function Kind_For_Return (Status : RL.Return_Legality_Status)
      return Wide_Semantic_Diagnostic_Kind is
   begin
      if Status in RL.Return_Legality_Result_Private_View_Barrier |
        RL.Return_Legality_Result_Limited_View_Barrier then
         return Wide_Semantic_Diagnostic_View_Barrier;
      elsif Status = RL.Return_Legality_Result_Static_Range_Violation then
         return Wide_Semantic_Diagnostic_Static_Range_Error;
      elsif Is_Unresolved (Status) then
         return Wide_Semantic_Diagnostic_Unresolved_Semantic_State;
      elsif Status = RL.Return_Legality_Indeterminate then
         return Wide_Semantic_Diagnostic_Indeterminate_State;
      else
         return Wide_Semantic_Diagnostic_Return_Legality_Error;
      end if;
   end Kind_For_Return;

   function Kind_For_Expression (Status : EL.Semantic_Legality_Status)
      return Wide_Semantic_Diagnostic_Kind is
   begin
      if Status in EL.Semantic_Legality_Private_View_Barrier |
        EL.Semantic_Legality_Limited_View_Barrier then
         return Wide_Semantic_Diagnostic_View_Barrier;
      elsif Status = EL.Semantic_Legality_Static_Range_Violation then
         return Wide_Semantic_Diagnostic_Static_Range_Error;
      elsif Is_Unresolved (Status) then
         return Wide_Semantic_Diagnostic_Unresolved_Semantic_State;
      elsif Status = EL.Semantic_Legality_Indeterminate then
         return Wide_Semantic_Diagnostic_Indeterminate_State;
      else
         return Wide_Semantic_Diagnostic_Conversion_Access_Aggregate_Error;
      end if;
   end Kind_For_Expression;

   function Kind_For_Cross_Unit (Status : CU.Cross_Unit_Semantic_Status)
      return Wide_Semantic_Diagnostic_Kind is
   begin
      if Status in CU.Cross_Unit_Semantic_Limited_View_Barrier |
        CU.Cross_Unit_Semantic_Private_View_Barrier then
         return Wide_Semantic_Diagnostic_View_Barrier;
      elsif Status in CU.Cross_Unit_Semantic_Missing_Dependency |
        CU.Cross_Unit_Semantic_Ambiguous_Dependency |
        CU.Cross_Unit_Semantic_Dependency_Overflow |
        CU.Cross_Unit_Semantic_Missing_Lookup |
        CU.Cross_Unit_Semantic_Ambiguous_Lookup |
        CU.Cross_Unit_Semantic_Lookup_Overflow then
         return Wide_Semantic_Diagnostic_Unresolved_Semantic_State;
      elsif Status = CU.Cross_Unit_Semantic_Indeterminate then
         return Wide_Semantic_Diagnostic_Indeterminate_State;
      else
         return Wide_Semantic_Diagnostic_Cross_Unit_Error;
      end if;
   end Kind_For_Cross_Unit;

   procedure Append
     (Model : in out Wide_Semantic_Diagnostic_Model;
      Info  : in out Wide_Semantic_Diagnostic_Info) is
   begin
      Info.Id := Wide_Semantic_Diagnostic_Id (Natural (Model.Diagnostics.Length) + 1);
      Info.Fingerprint := Diagnostic_Fingerprint (Info);
      Model.Diagnostics.Append (Info);
      case Info.Severity is
         when Wide_Semantic_Diagnostic_Error =>
            Model.Error_Total := Model.Error_Total + 1;
         when Wide_Semantic_Diagnostic_Warning =>
            Model.Warning_Total := Model.Warning_Total + 1;
         when Wide_Semantic_Diagnostic_Severity_Info =>
            Model.Info_Total := Model.Info_Total + 1;
      end case;
      Model.Result_Fingerprint := Mix (Model.Result_Fingerprint, Info.Fingerprint + 1);
   end Append;

   procedure Clear (Model : in out Wide_Semantic_Diagnostic_Model) is
   begin
      Model.Diagnostics.Clear;
      Model.Error_Total := 0;
      Model.Warning_Total := 0;
      Model.Info_Total := 0;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Assignments : AL.Assignment_Legality_Model;
      Returns     : RL.Return_Legality_Model;
      Expressions : EL.Semantic_Legality_Model;
      Flow        : FL.Flow_Legality_Model;
      Tasking     : TL.Tasking_Legality_Model;
      Tagged_Model      : TD.Tagged_Legality_Model;
      Instances   : GI.Instance_Legality_Model;
      Cross_Unit  : CU.Cross_Unit_Semantic_Model)
      return Wide_Semantic_Diagnostic_Model
   is
      Model : Wide_Semantic_Diagnostic_Model;
   begin
      for I in 1 .. AL.Legality_Count (Assignments) loop
         declare
            A : constant AL.Assignment_Legality_Info := AL.Legality_At (Assignments, I);
            D : Wide_Semantic_Diagnostic_Info;
         begin
            if A.Status /= AL.Assignment_Legality_Not_Checked and then not Is_Assignment_Legal (A.Status) then
               D.Family := Wide_Semantic_Diagnostic_Assignment;
               D.Kind := Kind_For_Assignment (A.Status);
               D.Severity := Severity_For_Unresolved (Is_Unresolved (A.Status));
               D.Node := A.Source_Node;
               D.Message := A.Message;
               D.Detail := A.Detail;
               D.Assignment := A.Id;
               D.Assignment_Status := A.Status;
               D.Start_Line := A.Start_Line;
               D.Start_Column := A.Start_Column;
               D.End_Line := A.End_Line;
               D.End_Column := A.End_Column;
               D.Source_Fingerprint := A.Fingerprint;
               Append (Model, D);
            end if;
         end;
      end loop;

      for I in 1 .. RL.Legality_Count (Returns) loop
         declare
            R : constant RL.Return_Legality_Info := RL.Legality_At (Returns, I);
            D : Wide_Semantic_Diagnostic_Info;
         begin
            if R.Status /= RL.Return_Legality_Not_Checked and then not Is_Return_Legal (R.Status) then
               D.Family := Wide_Semantic_Diagnostic_Return;
               D.Kind := Kind_For_Return (R.Status);
               D.Severity := Severity_For_Unresolved (Is_Unresolved (R.Status));
               D.Node := R.Return_Node;
               D.Message := R.Message;
               D.Detail := R.Detail;
               D.Return_Legality := R.Id;
               D.Return_Status := R.Status;
               D.Start_Line := R.Start_Line;
               D.Start_Column := R.Start_Column;
               D.End_Line := R.End_Line;
               D.End_Column := R.End_Column;
               D.Source_Fingerprint := R.Fingerprint;
               Append (Model, D);
            end if;
         end;
      end loop;

      for I in 1 .. EL.Legality_Count (Expressions) loop
         declare
            E : constant EL.Semantic_Legality_Info := EL.Legality_At (Expressions, I);
            D : Wide_Semantic_Diagnostic_Info;
         begin
            if E.Status /= EL.Semantic_Legality_Not_Checked and then not Is_Expression_Legal (E.Status) then
               D.Family := Wide_Semantic_Diagnostic_Conversion_Access_Aggregate;
               D.Kind := Kind_For_Expression (E.Status);
               D.Severity := Severity_For_Unresolved (Is_Unresolved (E.Status));
               D.Node := E.Node;
               D.Message := E.Message;
               D.Detail := E.Detail;
               D.Expression_Legality := E.Id;
               D.Expression_Status := E.Status;
               D.Start_Line := E.Start_Line;
               D.Start_Column := E.Start_Column;
               D.End_Line := E.End_Line;
               D.End_Column := E.End_Column;
               D.Source_Fingerprint := E.Fingerprint;
               Append (Model, D);
            end if;
         end;
      end loop;

      for I in 1 .. FL.Legality_Count (Flow) loop
         declare
            F : constant FL.Flow_Legality_Info := FL.Legality_At (Flow, I);
            D : Wide_Semantic_Diagnostic_Info;
         begin
            if F.Status /= FL.Flow_Legality_Not_Checked and then not Is_Flow_Legal (F.Status) then
               D.Family := Wide_Semantic_Diagnostic_Control_Flow;
               D.Kind := (if F.Status = FL.Flow_Legality_Indeterminate then
                            Wide_Semantic_Diagnostic_Indeterminate_State
                          elsif F.Status in FL.Flow_Legality_Condition_Unresolved |
                            FL.Flow_Legality_Case_Expression_Unresolved |
                            FL.Flow_Legality_Exit_Target_Missing |
                            FL.Flow_Legality_Goto_Target_Missing |
                            FL.Flow_Legality_Exception_Choice_Unresolved |
                            FL.Flow_Legality_Raise_Exception_Unresolved |
                            FL.Flow_Legality_Accept_Entry_Missing |
                            FL.Flow_Legality_Requeue_Target_Unresolved then
                            Wide_Semantic_Diagnostic_Unresolved_Semantic_State
                          else Wide_Semantic_Diagnostic_Control_Flow_Error);
               D.Severity := Severity_For_Unresolved (D.Kind = Wide_Semantic_Diagnostic_Unresolved_Semantic_State);
               D.Node := F.Node;
               D.Message := F.Message;
               D.Detail := F.Detail;
               D.Flow_Legality := F.Id;
               D.Flow_Status := F.Status;
               D.Start_Line := F.Start_Line;
               D.Start_Column := F.Start_Column;
               D.End_Line := F.End_Line;
               D.End_Column := F.End_Column;
               D.Source_Fingerprint := F.Fingerprint;
               Append (Model, D);
            end if;
         end;
      end loop;

      for I in 1 .. TL.Legality_Count (Tasking) loop
         declare
            T : constant TL.Tasking_Legality_Info := TL.Legality_At (Tasking, I);
            D : Wide_Semantic_Diagnostic_Info;
         begin
            if T.Status /= TL.Tasking_Legality_Not_Checked and then not Is_Tasking_Legal (T.Status) then
               D.Family := Wide_Semantic_Diagnostic_Tasking_Protected;
               D.Kind := (if T.Status = TL.Tasking_Legality_Indeterminate then
                            Wide_Semantic_Diagnostic_Indeterminate_State
                          elsif T.Status in TL.Tasking_Legality_Missing_Spec |
                            TL.Tasking_Legality_Missing_Body |
                            TL.Tasking_Legality_Entry_Missing |
                            TL.Tasking_Legality_Entry_Family_Index_Unresolved |
                            TL.Tasking_Legality_Barrier_Unresolved |
                            TL.Tasking_Legality_Accept_Entry_Missing |
                            TL.Tasking_Legality_Requeue_Target_Unresolved |
                            TL.Tasking_Legality_Protected_Private_Data_Unresolved then
                            Wide_Semantic_Diagnostic_Unresolved_Semantic_State
                          else Wide_Semantic_Diagnostic_Tasking_Protected_Error);
               D.Severity := Severity_For_Unresolved (D.Kind = Wide_Semantic_Diagnostic_Unresolved_Semantic_State);
               D.Node := T.Node;
               D.Message := T.Message;
               D.Detail := T.Detail;
               D.Tasking_Legality := T.Id;
               D.Tasking_Status := T.Status;
               D.Start_Line := T.Start_Line;
               D.Start_Column := T.Start_Column;
               D.End_Line := T.End_Line;
               D.End_Column := T.End_Column;
               D.Source_Fingerprint := T.Fingerprint;
               Append (Model, D);
            end if;
         end;
      end loop;

      for I in 1 .. TD.Legality_Count (Tagged_Model) loop
         declare
            T : constant TD.Tagged_Legality_Info := TD.Legality_At (Tagged_Model, I);
            D : Wide_Semantic_Diagnostic_Info;
         begin
            if T.Status /= TD.Tagged_Legality_Not_Checked and then not Is_Tagged_Legal (T.Status) then
               D.Family := Wide_Semantic_Diagnostic_Tagged_Derived;
               D.Kind := (if T.Status in TD.Tagged_Legality_Private_View_Barrier |
                            TD.Tagged_Legality_Limited_View_Barrier then
                            Wide_Semantic_Diagnostic_View_Barrier
                          elsif T.Status = TD.Tagged_Legality_Indeterminate then
                            Wide_Semantic_Diagnostic_Indeterminate_State
                          elsif T.Status in TD.Tagged_Legality_Parent_Unresolved |
                            TD.Tagged_Legality_Dispatching_Target_Unresolved then
                            Wide_Semantic_Diagnostic_Unresolved_Semantic_State
                          else Wide_Semantic_Diagnostic_Tagged_Derived_Error);
               D.Severity := Severity_For_Unresolved (D.Kind = Wide_Semantic_Diagnostic_Unresolved_Semantic_State);
               D.Node := T.Node;
               D.Message := T.Message;
               D.Detail := T.Detail;
               D.Tagged_Legality := T.Id;
               D.Tagged_Status := T.Status;
               D.Start_Line := T.Start_Line;
               D.Start_Column := T.Start_Column;
               D.End_Line := T.End_Line;
               D.End_Column := T.End_Column;
               D.Source_Fingerprint := T.Fingerprint;
               Append (Model, D);
            end if;
         end;
      end loop;

      for I in 1 .. GI.Legality_Count (Instances) loop
         declare
            G : constant GI.Instance_Legality_Info := GI.Legality_At (Instances, I);
            D : Wide_Semantic_Diagnostic_Info;
         begin
            if G.Status /= GI.Instance_Legality_Not_Checked and then not Is_Instance_Legal (G.Status) then
               D.Family := Wide_Semantic_Diagnostic_Generic_Instance;
               D.Kind := (if G.Status in GI.Instance_Legality_Body_Private_View_Barrier |
                            GI.Instance_Legality_Body_Limited_View_Barrier then
                            Wide_Semantic_Diagnostic_View_Barrier
                          elsif G.Status = GI.Instance_Legality_Representation_Static_Error then
                            Wide_Semantic_Diagnostic_Static_Range_Error
                          elsif G.Status in GI.Instance_Legality_Body_Cross_Unit_Unresolved |
                            GI.Instance_Legality_Formal_Package_Unresolved |
                            GI.Instance_Legality_Representation_Target_Unresolved |
                            GI.Instance_Legality_Representation_Target_Ambiguous then
                            Wide_Semantic_Diagnostic_Unresolved_Semantic_State
                          elsif G.Status = GI.Instance_Legality_Unknown then
                            Wide_Semantic_Diagnostic_Indeterminate_State
                          else Wide_Semantic_Diagnostic_Generic_Instance_Error);
               D.Severity := Severity_For_Unresolved (D.Kind = Wide_Semantic_Diagnostic_Unresolved_Semantic_State);
               D.Node := G.Node;
               D.Message := G.Message;
               D.Detail := G.Detail;
               D.Instance_Legality := G.Id;
               D.Instance_Status := G.Status;
               D.Source_Fingerprint := G.Fingerprint;
               Append (Model, D);
            end if;
         end;
      end loop;

      for I in 1 .. CU.Semantic_Count (Cross_Unit) loop
         declare
            C : constant CU.Cross_Unit_Semantic_Info := CU.Semantic_At (Cross_Unit, I);
            D : Wide_Semantic_Diagnostic_Info;
         begin
            if C.Status /= CU.Cross_Unit_Semantic_Not_Checked and then not Is_Cross_Unit_Legal (C.Status) then
               D.Family := Wide_Semantic_Diagnostic_Cross_Unit;
               D.Kind := Kind_For_Cross_Unit (C.Status);
               D.Severity := Severity_For_Unresolved (D.Kind = Wide_Semantic_Diagnostic_Unresolved_Semantic_State);
               D.Node := C.Node;
               D.Message := C.Message;
               D.Detail := C.Detail;
               D.Cross_Unit_Semantic := C.Id;
               D.Cross_Unit_Status := C.Status;
               D.Start_Line := C.Start_Line;
               D.Start_Column := C.Start_Column;
               D.End_Line := C.End_Line;
               D.End_Column := C.End_Column;
               D.Source_Fingerprint := C.Fingerprint;
               Append (Model, D);
            end if;
         end;
      end loop;

      return Model;
   end Build;

   function Diagnostic_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural is
   begin
      return Natural (Model.Diagnostics.Length);
   end Diagnostic_Count;

   function Diagnostic_At
     (Model : Wide_Semantic_Diagnostic_Model;
      Index : Positive) return Wide_Semantic_Diagnostic_Info is
   begin
      if Index > Diagnostic_Count (Model) then
         return (others => <>);
      end if;
      return Model.Diagnostics.Element (Index);
   end Diagnostic_At;

   function First_For_Node
     (Model : Wide_Semantic_Diagnostic_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Wide_Semantic_Diagnostic_Info is
   begin
      for Item of Model.Diagnostics loop
         if Item.Node = Node then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Family
     (Model  : Wide_Semantic_Diagnostic_Model;
      Family : Wide_Semantic_Diagnostic_Family) return Wide_Semantic_Diagnostic_Result_Set is
      Results : Wide_Semantic_Diagnostic_Result_Set;
   begin
      for Item of Model.Diagnostics loop
         if Item.Family = Family then
            Results.Items.Append (Item);
            Results.Fingerprint := Mix (Results.Fingerprint, Item.Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Rows_For_Family;

   function Rows_For_Kind
     (Model : Wide_Semantic_Diagnostic_Model;
      Kind  : Wide_Semantic_Diagnostic_Kind) return Wide_Semantic_Diagnostic_Result_Set is
      Results : Wide_Semantic_Diagnostic_Result_Set;
   begin
      for Item of Model.Diagnostics loop
         if Item.Kind = Kind then
            Results.Items.Append (Item);
            Results.Fingerprint := Mix (Results.Fingerprint, Item.Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Severity
     (Model    : Wide_Semantic_Diagnostic_Model;
      Severity : Wide_Semantic_Diagnostic_Severity) return Wide_Semantic_Diagnostic_Result_Set is
      Results : Wide_Semantic_Diagnostic_Result_Set;
   begin
      for Item of Model.Diagnostics loop
         if Item.Severity = Severity then
            Results.Items.Append (Item);
            Results.Fingerprint := Mix (Results.Fingerprint, Item.Fingerprint + 1);
         end if;
      end loop;
      return Results;
   end Rows_For_Severity;

   function Result_Count (Results : Wide_Semantic_Diagnostic_Result_Set) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Result_Count;

   function Result_At
     (Results : Wide_Semantic_Diagnostic_Result_Set;
      Index   : Positive) return Wide_Semantic_Diagnostic_Info is
   begin
      if Index > Result_Count (Results) then
         return (others => <>);
      end if;
      return Results.Items.Element (Index);
   end Result_At;

   function Count_Family
     (Model  : Wide_Semantic_Diagnostic_Model;
      Family : Wide_Semantic_Diagnostic_Family) return Natural is
      Count : Natural := 0;
   begin
      for Item of Model.Diagnostics loop
         if Item.Family = Family then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Family;

   function Count_Kind
     (Model : Wide_Semantic_Diagnostic_Model;
      Kind  : Wide_Semantic_Diagnostic_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Item of Model.Diagnostics loop
         if Item.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Count_Severity
     (Model    : Wide_Semantic_Diagnostic_Model;
      Severity : Wide_Semantic_Diagnostic_Severity) return Natural is
   begin
      case Severity is
         when Wide_Semantic_Diagnostic_Error => return Model.Error_Total;
         when Wide_Semantic_Diagnostic_Warning => return Model.Warning_Total;
         when Wide_Semantic_Diagnostic_Severity_Info => return Model.Info_Total;
      end case;
   end Count_Severity;

   function Error_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Warning_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural is
   begin
      return Model.Warning_Total;
   end Warning_Count;

   function Info_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural is
   begin
      return Model.Info_Total;
   end Info_Count;

   function Assignment_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural is
   begin
      return Count_Family (Model, Wide_Semantic_Diagnostic_Assignment);
   end Assignment_Count;

   function Return_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural is
   begin
      return Count_Family (Model, Wide_Semantic_Diagnostic_Return);
   end Return_Count;

   function Expression_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural is
   begin
      return Count_Family (Model, Wide_Semantic_Diagnostic_Conversion_Access_Aggregate);
   end Expression_Count;

   function Control_Flow_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural is
   begin
      return Count_Family (Model, Wide_Semantic_Diagnostic_Control_Flow);
   end Control_Flow_Count;

   function Tasking_Protected_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural is
   begin
      return Count_Family (Model, Wide_Semantic_Diagnostic_Tasking_Protected);
   end Tasking_Protected_Count;

   function Tagged_Derived_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural is
   begin
      return Count_Family (Model, Wide_Semantic_Diagnostic_Tagged_Derived);
   end Tagged_Derived_Count;

   function Generic_Instance_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural is
   begin
      return Count_Family (Model, Wide_Semantic_Diagnostic_Generic_Instance);
   end Generic_Instance_Count;

   function Cross_Unit_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural is
   begin
      return Count_Family (Model, Wide_Semantic_Diagnostic_Cross_Unit);
   end Cross_Unit_Count;

   function View_Barrier_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Wide_Semantic_Diagnostic_View_Barrier);
   end View_Barrier_Count;

   function Static_Range_Error_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Wide_Semantic_Diagnostic_Static_Range_Error);
   end Static_Range_Error_Count;

   function Unresolved_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Wide_Semantic_Diagnostic_Unresolved_Semantic_State);
   end Unresolved_Count;

   function Indeterminate_Count (Model : Wide_Semantic_Diagnostic_Model) return Natural is
   begin
      return Count_Kind (Model, Wide_Semantic_Diagnostic_Indeterminate_State);
   end Indeterminate_Count;

   function Fingerprint (Model : Wide_Semantic_Diagnostic_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Wide_Semantic_Legality_Diagnostics;
