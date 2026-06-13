with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Dataflow_Global_Depends_Legality is

   package CA renames Editor.Ada_Contract_Aspect_Legality;
   package DIF renames Editor.Ada_Definite_Initialization_Flow_Legality;

   use type DIF.Initialization_Legality_Status;
   use type DIF.Object_State;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   Modulus : constant Natural := 2_147_483_647;

   function Mix (Seed, Value : Natural) return Natural is
   begin
      return (Seed * 131 + Value + 23) mod Modulus;
   end Mix;

   function Text_Hash (Text : Unbounded_String) return Natural is
      S : constant String := Ada.Characters.Handling.To_Lower (To_String (Text));
      H : Natural := 0;
   begin
      for C of S loop
         H := Mix (H, Character'Pos (C));
      end loop;
      return H;
   end Text_Hash;

   function Context_Fingerprint (Info : Dataflow_Context_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Dataflow_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Dataflow_Effect_Kind'Pos (Info.Effect) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Object_Node) + 1);
      H := Mix (H, Natural (Info.Source_Node) + 1);
      H := Mix (H, Natural (Info.Target_Node) + 1);
      H := Mix (H, Text_Hash (Info.Object_Name));
      H := Mix (H, Text_Hash (Info.Source_Name));
      H := Mix (H, Text_Hash (Info.Target_Name));
      H := Mix (H, Global_Mode'Pos (Info.Declared_Global_Mode) + 1);
      H := Mix (H, Global_Mode'Pos (Info.Source_Global_Mode) + 1);
      H := Mix (H, Global_Mode'Pos (Info.Target_Global_Mode) + 1);
      H := Mix (H, Dependency_State'Pos (Info.Dependency) + 1);
      H := Mix (H, Boolean'Pos (Info.Reads_Object) + 1);
      H := Mix (H, Boolean'Pos (Info.Writes_Object) + 1);
      H := Mix (H, Boolean'Pos (Info.Duplicate_Effect) + 1);
      H := Mix (H, Boolean'Pos (Info.Missing_Refined_Global) + 1);
      H := Mix (H, Boolean'Pos (Info.Missing_Refined_Depends) + 1);
      H := Mix (H, Boolean'Pos (Info.Object_Resolved) + 1);
      H := Mix (H, DIF.Object_State'Pos (Info.Before_State) + 1);
      H := Mix (H, DIF.Object_State'Pos (Info.After_State) + 1);
      H := Mix (H, CA.Contract_Legality_Status'Pos (Info.Contract_Status) + 1);
      H := Mix (H, CA.Flow_Contract_State'Pos (Info.Flow_State) + 1);
      H := Mix (H, DIF.Initialization_Legality_Status'Pos (Info.Initialization_Status) + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.Start_Column);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.End_Column);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Context_Fingerprint;

   function Row_Fingerprint (Info : Dataflow_Legality_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Dataflow_Context_Kind'Pos (Info.Kind) + 1);
      H := Mix (H, Dataflow_Effect_Kind'Pos (Info.Effect) + 1);
      H := Mix (H, Dataflow_Legality_Status'Pos (Info.Status) + 1);
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Object_Node) + 1);
      H := Mix (H, Natural (Info.Source_Node) + 1);
      H := Mix (H, Natural (Info.Target_Node) + 1);
      H := Mix (H, Text_Hash (Info.Object_Name));
      H := Mix (H, Text_Hash (Info.Source_Name));
      H := Mix (H, Text_Hash (Info.Target_Name));
      H := Mix (H, Global_Mode'Pos (Info.Declared_Global_Mode) + 1);
      H := Mix (H, Dependency_State'Pos (Info.Dependency) + 1);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Row_Fingerprint;

   function Contract_Error (Status : Contract_Legality_Status) return Boolean is
   begin
      return Status not in
        CA.Contract_Legality_Not_Checked |
        CA.Contract_Legality_Legal_Precondition |
        CA.Contract_Legality_Legal_Postcondition |
        CA.Contract_Legality_Legal_Invariant |
        CA.Contract_Legality_Legal_Predicate |
        CA.Contract_Legality_Legal_Assertion |
        CA.Contract_Legality_Legal_Contract_Case |
        CA.Contract_Legality_Legal_Flow_Aspect;
   end Contract_Error;

   function Initialization_Error (Status : Initialization_Legality_Status) return Boolean is
   begin
      return Status not in
        DIF.Initialization_Legality_Not_Checked |
        DIF.Initialization_Legality_Definitely_Initialized |
        DIF.Initialization_Legality_Default_Initialized |
        DIF.Initialization_Legality_Explicitly_Initialized |
        DIF.Initialization_Legality_Component_Initialized |
        DIF.Initialization_Legality_Out_Parameter_Assigned |
        DIF.Initialization_Legality_Return_Object_Initialized |
        DIF.Initialization_Legality_Exception_Path_Preserved |
        DIF.Initialization_Legality_Finalization_Path_Preserved |
        DIF.Initialization_Legality_Unreachable_Initialization;
   end Initialization_Error;

   function Allows_Read (Mode : Global_Mode) return Boolean is
   begin
      return Mode in Global_Mode_In | Global_Mode_In_Out | Global_Mode_Proof_In;
   end Allows_Read;

   function Allows_Write (Mode : Global_Mode) return Boolean is
   begin
      return Mode in Global_Mode_Out | Global_Mode_In_Out;
   end Allows_Write;

   function Is_Legal_Status (Status : Dataflow_Legality_Status) return Boolean is
   begin
      return Status in
        Dataflow_Legality_Legal_Read |
        Dataflow_Legality_Legal_Write |
        Dataflow_Legality_Legal_Read_Write |
        Dataflow_Legality_Legal_Null_Effect |
        Dataflow_Legality_Legal_Depends_Edge |
        Dataflow_Legality_Legal_Refinement;
   end Is_Legal_Status;

   function Is_Global_Error (Status : Dataflow_Legality_Status) return Boolean is
   begin
      return Status in
        Dataflow_Legality_Read_Not_In_Global |
        Dataflow_Legality_Write_Not_In_Global |
        Dataflow_Legality_Write_To_In_Global |
        Dataflow_Legality_Read_From_Out_Global |
        Dataflow_Legality_Effect_Violates_Null_Global |
        Dataflow_Legality_Refined_Global_Missing_Item |
        Dataflow_Legality_Duplicate_Effect |
        Dataflow_Legality_Mode_Mismatch |
        Dataflow_Legality_Unresolved_Object;
   end Is_Global_Error;

   function Is_Depends_Error (Status : Dataflow_Legality_Status) return Boolean is
   begin
      return Status in
        Dataflow_Legality_Depends_Missing_Source |
        Dataflow_Legality_Depends_Source_Not_Input |
        Dataflow_Legality_Depends_Target_Not_Output |
        Dataflow_Legality_Depends_Cycle |
        Dataflow_Legality_Depends_Duplicate |
        Dataflow_Legality_Refined_Depends_Missing_Edge;
   end Is_Depends_Error;

   function Is_Initialization_Error (Status : Dataflow_Legality_Status) return Boolean is
   begin
      return Status in
        Dataflow_Legality_Read_Before_Write |
        Dataflow_Legality_Out_Parameter_Not_Assigned |
        Dataflow_Legality_In_Out_Parameter_Conditionally_Assigned |
        Dataflow_Legality_Use_After_Finalization;
   end Is_Initialization_Error;

   function Is_Linked_Error (Status : Dataflow_Legality_Status) return Boolean is
   begin
      return Status in
        Dataflow_Legality_Linked_Contract_Error |
        Dataflow_Legality_Linked_Initialization_Error;
   end Is_Linked_Error;

   function Status_For (Info : Dataflow_Context_Info) return Dataflow_Legality_Status is
   begin
      if not Info.Object_Resolved then
         return Dataflow_Legality_Unresolved_Object;
      elsif Contract_Error (Info.Contract_Status) then
         return Dataflow_Legality_Linked_Contract_Error;
      elsif Info.Initialization_Status = DIF.Initialization_Legality_Read_Before_Write or else
            (Info.Reads_Object and then Info.Before_State = DIF.Object_State_Uninitialized) then
         return Dataflow_Legality_Read_Before_Write;
      elsif Info.Initialization_Status = DIF.Initialization_Legality_Out_Parameter_Not_Assigned then
         return Dataflow_Legality_Out_Parameter_Not_Assigned;
      elsif Info.Initialization_Status = DIF.Initialization_Legality_In_Out_Parameter_Conditionally_Assigned then
         return Dataflow_Legality_In_Out_Parameter_Conditionally_Assigned;
      elsif Info.Initialization_Status = DIF.Initialization_Legality_Use_After_Finalization or else
            Info.Before_State = DIF.Object_State_Moved_Or_Finalized then
         return Dataflow_Legality_Use_After_Finalization;
      elsif Initialization_Error (Info.Initialization_Status) then
         return Dataflow_Legality_Linked_Initialization_Error;
      elsif Info.Missing_Refined_Global then
         return Dataflow_Legality_Refined_Global_Missing_Item;
      elsif Info.Missing_Refined_Depends then
         return Dataflow_Legality_Refined_Depends_Missing_Edge;
      elsif Info.Duplicate_Effect then
         return Dataflow_Legality_Duplicate_Effect;
      end if;

      if Info.Effect = Dataflow_Effect_Null or else
        (not Info.Reads_Object and then not Info.Writes_Object and then
         Info.Dependency = Dependency_State_Not_Applicable)
      then
         if Info.Declared_Global_Mode = Global_Mode_Null then
            return Dataflow_Legality_Legal_Null_Effect;
         elsif Info.Declared_Global_Mode = Global_Mode_In or else
               Info.Declared_Global_Mode = Global_Mode_Out or else
               Info.Declared_Global_Mode = Global_Mode_In_Out or else
               Info.Declared_Global_Mode = Global_Mode_Proof_In
         then
            return Dataflow_Legality_Mode_Mismatch;
         else
            return Dataflow_Legality_Legal_Null_Effect;
         end if;
      end if;

      if Info.Declared_Global_Mode = Global_Mode_Null and then
        (Info.Reads_Object or else Info.Writes_Object)
      then
         return Dataflow_Legality_Effect_Violates_Null_Global;
      end if;

      if Info.Writes_Object and then Info.Declared_Global_Mode = Global_Mode_Not_Declared then
         return Dataflow_Legality_Write_Not_In_Global;
      elsif Info.Writes_Object and then not Allows_Write (Info.Declared_Global_Mode) then
         return Dataflow_Legality_Write_To_In_Global;
      elsif Info.Reads_Object and then Info.Declared_Global_Mode = Global_Mode_Not_Declared then
         return Dataflow_Legality_Read_Not_In_Global;
      elsif Info.Reads_Object and then not Allows_Read (Info.Declared_Global_Mode) then
         return Dataflow_Legality_Read_From_Out_Global;
      end if;

      case Info.Dependency is
         when Dependency_State_Output_Missing_Source =>
            return Dataflow_Legality_Depends_Missing_Source;
         when Dependency_State_Source_Not_Global_Input =>
            return Dataflow_Legality_Depends_Source_Not_Input;
         when Dependency_State_Target_Not_Global_Output =>
            return Dataflow_Legality_Depends_Target_Not_Output;
         when Dependency_State_Cycle =>
            return Dataflow_Legality_Depends_Cycle;
         when Dependency_State_Duplicate =>
            return Dataflow_Legality_Depends_Duplicate;
         when Dependency_State_Unresolved =>
            return Dataflow_Legality_Indeterminate;
         when others =>
            null;
      end case;

      if Info.Effect = Dataflow_Effect_Depends_Edge then
         if not Allows_Read (Info.Source_Global_Mode) then
            return Dataflow_Legality_Depends_Source_Not_Input;
         elsif not Allows_Write (Info.Target_Global_Mode) then
            return Dataflow_Legality_Depends_Target_Not_Output;
         else
            return Dataflow_Legality_Legal_Depends_Edge;
         end if;
      elsif Info.Effect = Dataflow_Effect_Refinement then
         return Dataflow_Legality_Legal_Refinement;
      elsif Info.Reads_Object and then Info.Writes_Object then
         return Dataflow_Legality_Legal_Read_Write;
      elsif Info.Writes_Object then
         return Dataflow_Legality_Legal_Write;
      elsif Info.Reads_Object then
         return Dataflow_Legality_Legal_Read;
      elsif Info.Effect = Dataflow_Effect_Unknown then
         return Dataflow_Legality_Indeterminate;
      else
         return Dataflow_Legality_Legal_Null_Effect;
      end if;
   end Status_For;

   function Message_For (Status : Dataflow_Legality_Status) return Unbounded_String is
   begin
      case Status is
         when Dataflow_Legality_Legal_Read =>
            return To_Unbounded_String ("read effect is covered by Global input mode");
         when Dataflow_Legality_Legal_Write =>
            return To_Unbounded_String ("write effect is covered by Global output mode");
         when Dataflow_Legality_Legal_Read_Write =>
            return To_Unbounded_String ("read/write effect is covered by Global in out mode");
         when Dataflow_Legality_Legal_Null_Effect =>
            return To_Unbounded_String ("null dataflow effect is legal");
         when Dataflow_Legality_Legal_Depends_Edge =>
            return To_Unbounded_String ("Depends edge is covered by Global modes");
         when Dataflow_Legality_Legal_Refinement =>
            return To_Unbounded_String ("flow refinement is legal");
         when Dataflow_Legality_Read_Not_In_Global =>
            return To_Unbounded_String ("object read is not covered by Global input effects");
         when Dataflow_Legality_Write_Not_In_Global =>
            return To_Unbounded_String ("object write is not covered by Global output effects");
         when Dataflow_Legality_Write_To_In_Global =>
            return To_Unbounded_String ("Global input item is written");
         when Dataflow_Legality_Read_From_Out_Global =>
            return To_Unbounded_String ("Global output-only item is read");
         when Dataflow_Legality_Effect_Violates_Null_Global =>
            return To_Unbounded_String ("effect violates null Global aspect");
         when Dataflow_Legality_Depends_Missing_Source =>
            return To_Unbounded_String ("Depends output is missing a source");
         when Dataflow_Legality_Depends_Source_Not_Input =>
            return To_Unbounded_String ("Depends source is not a Global input");
         when Dataflow_Legality_Depends_Target_Not_Output =>
            return To_Unbounded_String ("Depends target is not a Global output");
         when Dataflow_Legality_Depends_Cycle =>
            return To_Unbounded_String ("Depends graph contains a cycle");
         when Dataflow_Legality_Depends_Duplicate =>
            return To_Unbounded_String ("duplicate Depends edge");
         when Dataflow_Legality_Read_Before_Write =>
            return To_Unbounded_String ("dataflow reads an object before definite initialization");
         when Dataflow_Legality_Out_Parameter_Not_Assigned =>
            return To_Unbounded_String ("out parameter is not assigned on all exits");
         when Dataflow_Legality_Use_After_Finalization =>
            return To_Unbounded_String ("dataflow uses an object after finalization");
         when Dataflow_Legality_Indeterminate =>
            return To_Unbounded_String ("dataflow legality is indeterminate");
         when others =>
            return To_Unbounded_String ("Global/Depends dataflow legality error");
      end case;
   end Message_For;

   procedure Add_Row (Model : in out Dataflow_Legality_Model; Row : Dataflow_Legality_Info) is
   begin
      Model.Rows.Append (Row);
      if Is_Legal_Status (Row.Status) then
         Model.Legal_Total := Model.Legal_Total + 1;
      else
         Model.Error_Total := Model.Error_Total + 1;
      end if;
      if Is_Global_Error (Row.Status) then
         Model.Global_Error_Total := Model.Global_Error_Total + 1;
      end if;
      if Is_Depends_Error (Row.Status) then
         Model.Depends_Error_Total := Model.Depends_Error_Total + 1;
      end if;
      if Is_Initialization_Error (Row.Status) then
         Model.Initialization_Error_Total := Model.Initialization_Error_Total + 1;
      end if;
      if Is_Linked_Error (Row.Status) then
         Model.Linked_Error_Total := Model.Linked_Error_Total + 1;
      end if;
      if Row.Status = Dataflow_Legality_Indeterminate then
         Model.Indeterminate_Total := Model.Indeterminate_Total + 1;
      end if;
      Model.Fingerprint := Mix (Model.Fingerprint, Row.Fingerprint);
   end Add_Row;

   procedure Clear (Model : in out Dataflow_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context (Model : in out Dataflow_Context_Model; Info : Dataflow_Context_Info) is
   begin
      Model.Contexts.Append (Info);
      Model.Fingerprint := Mix (Model.Fingerprint, Context_Fingerprint (Info));
   end Add_Context;

   function Context_Count (Model : Dataflow_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At (Model : Dataflow_Context_Model; Index : Positive) return Dataflow_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Dataflow_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build (Contexts : Dataflow_Context_Model) return Dataflow_Legality_Model is
      Model : Dataflow_Legality_Model;
      Next  : Dataflow_Legality_Id := 1;
   begin
      for C of Contexts.Contexts loop
         declare
            R : Dataflow_Legality_Info;
         begin
            R.Id := Next;
            R.Context := C.Id;
            R.Kind := C.Kind;
            R.Effect := C.Effect;
            R.Status := Status_For (C);
            R.Node := C.Node;
            R.Object_Node := C.Object_Node;
            R.Source_Node := C.Source_Node;
            R.Target_Node := C.Target_Node;
            R.Object_Name := C.Object_Name;
            R.Source_Name := C.Source_Name;
            R.Target_Name := C.Target_Name;
            R.Declared_Global_Mode := C.Declared_Global_Mode;
            R.Source_Global_Mode := C.Source_Global_Mode;
            R.Target_Global_Mode := C.Target_Global_Mode;
            R.Dependency := C.Dependency;
            R.Contract_Status := C.Contract_Status;
            R.Flow_State := C.Flow_State;
            R.Initialization_Status := C.Initialization_Status;
            R.Start_Line := C.Start_Line;
            R.Start_Column := C.Start_Column;
            R.End_Line := C.End_Line;
            R.End_Column := C.End_Column;
            R.Source_Fingerprint := C.Source_Fingerprint;
            R.Message := Message_For (R.Status);
            R.Detail := To_Unbounded_String (Dataflow_Effect_Kind'Image (R.Effect));
            R.Fingerprint := Row_Fingerprint (R);
            Add_Row (Model, R);
            Next := Next + 1;
         end;
      end loop;
      Model.Fingerprint := Mix (Model.Fingerprint, Fingerprint (Contexts));
      return Model;
   end Build;

   function Row_Count (Model : Dataflow_Legality_Model) return Natural is
   begin
      return Natural (Model.Rows.Length);
   end Row_Count;

   function Row_At (Model : Dataflow_Legality_Model; Index : Positive) return Dataflow_Legality_Info is
   begin
      return Model.Rows.Element (Index);
   end Row_At;

   function First_For_Node (Model : Dataflow_Legality_Model; Node : Editor.Ada_Syntax_Tree.Node_Id)
                            return Dataflow_Legality_Info is
   begin
      for R of Model.Rows loop
         if R.Node = Node then
            return R;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function First_For_Object (Model : Dataflow_Legality_Model; Name : String)
                              return Dataflow_Legality_Info is
      Key : constant String := Ada.Characters.Handling.To_Lower (Name);
   begin
      for R of Model.Rows loop
         if Ada.Characters.Handling.To_Lower (To_String (R.Object_Name)) = Key then
            return R;
         end if;
      end loop;
      return (others => <>);
   end First_For_Object;

   function Rows_For_Status (Model : Dataflow_Legality_Model; Status : Dataflow_Legality_Status)
                             return Dataflow_Result_Set is
      Results : Dataflow_Result_Set;
   begin
      for R of Model.Rows loop
         if R.Status = Status then
            Results.Rows.Append (R);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind (Model : Dataflow_Legality_Model; Kind : Dataflow_Context_Kind)
                           return Dataflow_Result_Set is
      Results : Dataflow_Result_Set;
   begin
      for R of Model.Rows loop
         if R.Kind = Kind then
            Results.Rows.Append (R);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Effect (Model : Dataflow_Legality_Model; Effect : Dataflow_Effect_Kind)
                             return Dataflow_Result_Set is
      Results : Dataflow_Result_Set;
   begin
      for R of Model.Rows loop
         if R.Effect = Effect then
            Results.Rows.Append (R);
         end if;
      end loop;
      return Results;
   end Rows_For_Effect;

   function Result_Count (Results : Dataflow_Result_Set) return Natural is
   begin
      return Natural (Results.Rows.Length);
   end Result_Count;

   function Result_At (Results : Dataflow_Result_Set; Index : Positive) return Dataflow_Legality_Info is
   begin
      return Results.Rows.Element (Index);
   end Result_At;

   function Count_Status (Model : Dataflow_Legality_Model; Status : Dataflow_Legality_Status)
                          return Natural is
      Total : Natural := 0;
   begin
      for R of Model.Rows loop
         if R.Status = Status then Total := Total + 1; end if;
      end loop;
      return Total;
   end Count_Status;

   function Count_Kind (Model : Dataflow_Legality_Model; Kind : Dataflow_Context_Kind) return Natural is
      Total : Natural := 0;
   begin
      for R of Model.Rows loop
         if R.Kind = Kind then Total := Total + 1; end if;
      end loop;
      return Total;
   end Count_Kind;

   function Count_Effect (Model : Dataflow_Legality_Model; Effect : Dataflow_Effect_Kind) return Natural is
      Total : Natural := 0;
   begin
      for R of Model.Rows loop
         if R.Effect = Effect then Total := Total + 1; end if;
      end loop;
      return Total;
   end Count_Effect;

   function Legal_Count (Model : Dataflow_Legality_Model) return Natural is
   begin
      return Model.Legal_Total;
   end Legal_Count;

   function Error_Count (Model : Dataflow_Legality_Model) return Natural is
   begin
      return Model.Error_Total;
   end Error_Count;

   function Global_Error_Count (Model : Dataflow_Legality_Model) return Natural is
   begin
      return Model.Global_Error_Total;
   end Global_Error_Count;

   function Depends_Error_Count (Model : Dataflow_Legality_Model) return Natural is
   begin
      return Model.Depends_Error_Total;
   end Depends_Error_Count;

   function Initialization_Error_Count (Model : Dataflow_Legality_Model) return Natural is
   begin
      return Model.Initialization_Error_Total;
   end Initialization_Error_Count;

   function Linked_Error_Count (Model : Dataflow_Legality_Model) return Natural is
   begin
      return Model.Linked_Error_Total;
   end Linked_Error_Count;

   function Indeterminate_Count (Model : Dataflow_Legality_Model) return Natural is
   begin
      return Model.Indeterminate_Total;
   end Indeterminate_Count;

   function Fingerprint (Model : Dataflow_Legality_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Dataflow_Global_Depends_Legality;
