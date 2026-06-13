with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Tasking_Protected_Legality is

   use type Editor.Ada_Control_Flow_Legality.Flow_Legality_Id;
   use type Editor.Ada_Syntax_Tree.Node_Id;

   function Mix (A, B : Natural) return Natural is
   begin
      return ((A * 307) + B + 251) mod 1_000_000_007;
   end Mix;

   function Bool_Slot (Value : Boolean) return Natural is
   begin
      if Value then
         return 2;
      else
         return 1;
      end if;
   end Bool_Slot;

   function Kind_Slot (Kind : Tasking_Context_Kind) return Natural is
   begin
      return Tasking_Context_Kind'Pos (Kind) + 1;
   end Kind_Slot;

   function Status_Slot (Status : Tasking_Legality_Status) return Natural is
   begin
      return Tasking_Legality_Status'Pos (Status) + 1;
   end Status_Slot;

   function Context_Fingerprint (Context : Tasking_Context_Info) return Natural is
      H : Natural := Natural (Context.Id) + 1;
   begin
      H := Mix (H, Kind_Slot (Context.Kind));
      H := Mix (H, Natural (Context.Node) + 1);
      H := Mix (H, Natural (Context.Spec_Node) + 1);
      H := Mix (H, Natural (Context.Body_Node) + 1);
      H := Mix (H, Natural (Context.Entry_Node) + 1);
      H := Mix (H, Natural (Context.Barrier_Node) + 1);
      H := Mix (H, Length (Context.Normalized_Unit_Name) + 1);
      H := Mix (H, Length (Context.Normalized_Entry_Name) + 1);
      H := Mix (H, Bool_Slot (Context.Spec_Resolved));
      H := Mix (H, Bool_Slot (Context.Body_Resolved));
      H := Mix (H, Bool_Slot (Context.Has_Body));
      H := Mix (H, Bool_Slot (Context.Duplicate_Body));
      H := Mix (H, Bool_Slot (Context.Kind_Matches));
      H := Mix (H, Bool_Slot (Context.Profile_Matches));
      H := Mix (H, Bool_Slot (Context.Entry_Resolved));
      H := Mix (H, Bool_Slot (Context.Entry_Duplicate));
      H := Mix (H, Bool_Slot (Context.Entry_Is_Family));
      H := Mix (H, Bool_Slot (Context.Entry_Family_Index_Resolved));
      H := Mix (H, Bool_Slot (Context.Entry_Family_Index_Compatible));
      H := Mix (H, Bool_Slot (Context.Entry_Family_Index_Static));
      H := Mix (H, Bool_Slot (Context.Barrier_Present));
      H := Mix (H, Bool_Slot (Context.Barrier_Type_Resolved));
      H := Mix (H, Bool_Slot (Context.Barrier_Is_Boolean));
      H := Mix (H, Bool_Slot (Context.Accept_Is_In_Task_Body));
      H := Mix (H, Bool_Slot (Context.Requeue_Target_Resolved));
      H := Mix (H, Bool_Slot (Context.Requeue_Target_Is_Entry));
      H := Mix (H, Bool_Slot (Context.Requeue_With_Abort_Allowed));
      H := Mix (H, Bool_Slot (Context.Protected_Function_Modifies_State));
      H := Mix (H, Bool_Slot (Context.Protected_Function_Calls_Entry));
      H := Mix (H, Bool_Slot (Context.Protected_Procedure_Has_Barrier));
      H := Mix (H, Bool_Slot (Context.Protected_Private_Data_Resolved));
      H := Mix (H, Bool_Slot (Context.Select_Has_Illegal_Alternative));
      H := Mix (H, Natural (Context.Flow_Legality) + 1);
      H := Mix (H, Context.Start_Line);
      H := Mix (H, Context.Start_Column);
      H := Mix (H, Context.End_Line);
      H := Mix (H, Context.End_Column);
      return H;
   end Context_Fingerprint;

   function Result_Fingerprint (Info : Tasking_Legality_Info) return Natural is
      H : Natural := Natural (Info.Id) + 1;
   begin
      H := Mix (H, Natural (Info.Context) + 1);
      H := Mix (H, Kind_Slot (Info.Kind));
      H := Mix (H, Natural (Info.Node) + 1);
      H := Mix (H, Natural (Info.Spec_Node) + 1);
      H := Mix (H, Natural (Info.Body_Node) + 1);
      H := Mix (H, Natural (Info.Entry_Node) + 1);
      H := Mix (H, Natural (Info.Barrier_Node) + 1);
      H := Mix (H, Status_Slot (Info.Status));
      H := Mix (H, Length (Info.Normalized_Unit_Name) + 1);
      H := Mix (H, Length (Info.Normalized_Entry_Name) + 1);
      H := Mix (H, Natural (Info.Flow_Legality) + 1);
      H := Mix (H, Info.Start_Line);
      H := Mix (H, Info.Start_Column);
      H := Mix (H, Info.End_Line);
      H := Mix (H, Info.End_Column);
      H := Mix (H, Info.Source_Fingerprint + 1);
      return H;
   end Result_Fingerprint;

   function Is_Compatible (Status : Tasking_Legality_Status) return Boolean is
   begin
      return Status in Tasking_Legality_Legal_Task_Type |
        Tasking_Legality_Legal_Task_Body |
        Tasking_Legality_Legal_Protected_Type |
        Tasking_Legality_Legal_Protected_Body |
        Tasking_Legality_Legal_Entry_Declaration |
        Tasking_Legality_Legal_Entry_Body |
        Tasking_Legality_Legal_Entry_Family |
        Tasking_Legality_Legal_Accept |
        Tasking_Legality_Legal_Requeue |
        Tasking_Legality_Legal_Protected_Function |
        Tasking_Legality_Legal_Protected_Procedure |
        Tasking_Legality_Legal_Protected_Entry |
        Tasking_Legality_Legal_Select;
   end Is_Compatible;

   function Is_Warning (Status : Tasking_Legality_Status) return Boolean is
   begin
      return Status = Tasking_Legality_Indeterminate;
   end Is_Warning;

   function Is_Error (Status : Tasking_Legality_Status) return Boolean is
   begin
      return not Is_Compatible (Status)
        and then not Is_Warning (Status)
        and then Status /= Tasking_Legality_Not_Checked;
   end Is_Error;

   function Flow_Is_Error
     (Flow : Editor.Ada_Control_Flow_Legality.Flow_Legality_Model;
      Id   : Editor.Ada_Control_Flow_Legality.Flow_Legality_Id) return Boolean is
   begin
      if Id = Editor.Ada_Control_Flow_Legality.No_Flow_Legality then
         return False;
      end if;

      for Index in 1 .. Editor.Ada_Control_Flow_Legality.Legality_Count (Flow) loop
         declare
            Row : constant Editor.Ada_Control_Flow_Legality.Flow_Legality_Info :=
              Editor.Ada_Control_Flow_Legality.Legality_At (Flow, Index);
         begin
            if Row.Id = Id then
               return Row.Status not in
                 Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Boolean_Condition |
                 Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Case_Statement |
                 Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Exit |
                 Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Goto |
                 Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Label |
                 Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Exception_Handler |
                 Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Raise |
                 Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Select |
                 Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Accept |
                 Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Requeue |
                 Editor.Ada_Control_Flow_Legality.Flow_Legality_Legal_Return_Path;
            end if;
         end;
      end loop;

      return False;
   end Flow_Is_Error;

   function Message_For (Status : Tasking_Legality_Status) return String is
   begin
      case Status is
         when Tasking_Legality_Legal_Task_Type => return "task type is legal";
         when Tasking_Legality_Legal_Task_Body => return "task body matches its specification";
         when Tasking_Legality_Legal_Protected_Type => return "protected type is legal";
         when Tasking_Legality_Legal_Protected_Body => return "protected body matches its specification";
         when Tasking_Legality_Legal_Entry_Declaration => return "entry declaration is legal";
         when Tasking_Legality_Legal_Entry_Body => return "entry body is legal";
         when Tasking_Legality_Legal_Entry_Family => return "entry family is legal";
         when Tasking_Legality_Legal_Accept => return "accept statement entry is legal";
         when Tasking_Legality_Legal_Requeue => return "requeue statement is legal";
         when Tasking_Legality_Legal_Protected_Function => return "protected function restrictions are satisfied";
         when Tasking_Legality_Legal_Protected_Procedure => return "protected procedure restrictions are satisfied";
         when Tasking_Legality_Legal_Protected_Entry => return "protected entry barrier is legal";
         when Tasking_Legality_Legal_Select => return "select statement is legal";
         when Tasking_Legality_Missing_Spec => return "task/protected body has no resolved specification";
         when Tasking_Legality_Missing_Body => return "task/protected specification has no resolved body";
         when Tasking_Legality_Duplicate_Body => return "task/protected body is duplicated";
         when Tasking_Legality_Kind_Mismatch => return "task/protected body kind does not match specification";
         when Tasking_Legality_Profile_Mismatch => return "entry or operation profile does not conform";
         when Tasking_Legality_Entry_Missing => return "entry target is missing";
         when Tasking_Legality_Entry_Duplicate => return "entry declaration/body is duplicated";
         when Tasking_Legality_Entry_Family_Index_Mismatch => return "entry family index subtype is incompatible";
         when Tasking_Legality_Entry_Family_Index_Unresolved => return "entry family index subtype is unresolved";
         when Tasking_Legality_Barrier_Unresolved => return "protected entry barrier type is unresolved";
         when Tasking_Legality_Barrier_Not_Boolean => return "protected entry barrier is not Boolean";
         when Tasking_Legality_Barrier_Non_Static_Family_Index => return "entry family index constraint is not static";
         when Tasking_Legality_Accept_Entry_Missing => return "accept statement entry is missing";
         when Tasking_Legality_Accept_Not_In_Task_Body => return "accept statement is outside a task body";
         when Tasking_Legality_Accept_Profile_Mismatch => return "accept statement profile does not match entry";
         when Tasking_Legality_Requeue_Target_Unresolved => return "requeue target is unresolved";
         when Tasking_Legality_Requeue_To_Non_Entry => return "requeue target is not an entry";
         when Tasking_Legality_Requeue_With_Abort_Not_Allowed => return "requeue with abort is not allowed here";
         when Tasking_Legality_Protected_Function_Modifies_State => return "protected function modifies protected state";
         when Tasking_Legality_Protected_Function_Calls_Entry => return "protected function calls an entry";
         when Tasking_Legality_Protected_Procedure_Barrier => return "protected procedure illegally has a barrier";
         when Tasking_Legality_Protected_Entry_Barrier_Missing => return "protected entry is missing a barrier";
         when Tasking_Legality_Protected_Private_Data_Unresolved => return "protected private data reference is unresolved";
         when Tasking_Legality_Select_Alternative_Error => return "select statement has an illegal alternative";
         when Tasking_Legality_Flow_Legality_Error => return "linked control-flow legality is illegal";
         when Tasking_Legality_Indeterminate => return "tasking/protected legality is indeterminate";
         when Tasking_Legality_Not_Checked => return "tasking/protected legality was not checked";
      end case;
   end Message_For;

   function Detail_For
     (Context : Tasking_Context_Info;
      Status  : Tasking_Legality_Status) return String is
   begin
      case Status is
         when Tasking_Legality_Missing_Spec |
              Tasking_Legality_Missing_Body |
              Tasking_Legality_Duplicate_Body |
              Tasking_Legality_Kind_Mismatch =>
            return "unit=" & To_String (Context.Normalized_Unit_Name);
         when Tasking_Legality_Entry_Missing |
              Tasking_Legality_Entry_Duplicate |
              Tasking_Legality_Accept_Entry_Missing |
              Tasking_Legality_Requeue_Target_Unresolved |
              Tasking_Legality_Requeue_To_Non_Entry =>
            return "entry=" & To_String (Context.Normalized_Entry_Name);
         when Tasking_Legality_Flow_Legality_Error =>
            return "flow=" & Natural'Image (Natural (Context.Flow_Legality));
         when others =>
            return "context=" & Tasking_Context_Kind'Image (Context.Kind);
      end case;
   end Detail_For;

   function Classify
     (Context : Tasking_Context_Info;
      Flow    : Editor.Ada_Control_Flow_Legality.Flow_Legality_Model)
      return Tasking_Legality_Status is
   begin
      if Flow_Is_Error (Flow, Context.Flow_Legality) then
         return Tasking_Legality_Flow_Legality_Error;
      end if;

      case Context.Kind is
         when Tasking_Context_Task_Type =>
            if not Context.Has_Body then
               return Tasking_Legality_Missing_Body;
            elsif Context.Duplicate_Body then
               return Tasking_Legality_Duplicate_Body;
            else
               return Tasking_Legality_Legal_Task_Type;
            end if;

         when Tasking_Context_Task_Body =>
            if not Context.Spec_Resolved then
               return Tasking_Legality_Missing_Spec;
            elsif Context.Duplicate_Body then
               return Tasking_Legality_Duplicate_Body;
            elsif not Context.Kind_Matches then
               return Tasking_Legality_Kind_Mismatch;
            elsif not Context.Profile_Matches then
               return Tasking_Legality_Profile_Mismatch;
            else
               return Tasking_Legality_Legal_Task_Body;
            end if;

         when Tasking_Context_Protected_Type =>
            if not Context.Has_Body then
               return Tasking_Legality_Missing_Body;
            elsif Context.Duplicate_Body then
               return Tasking_Legality_Duplicate_Body;
            else
               return Tasking_Legality_Legal_Protected_Type;
            end if;

         when Tasking_Context_Protected_Body =>
            if not Context.Spec_Resolved then
               return Tasking_Legality_Missing_Spec;
            elsif Context.Duplicate_Body then
               return Tasking_Legality_Duplicate_Body;
            elsif not Context.Kind_Matches then
               return Tasking_Legality_Kind_Mismatch;
            elsif not Context.Profile_Matches then
               return Tasking_Legality_Profile_Mismatch;
            else
               return Tasking_Legality_Legal_Protected_Body;
            end if;

         when Tasking_Context_Entry_Declaration =>
            if Context.Entry_Duplicate then
               return Tasking_Legality_Entry_Duplicate;
            elsif not Context.Entry_Resolved then
               return Tasking_Legality_Entry_Missing;
            elsif not Context.Profile_Matches then
               return Tasking_Legality_Profile_Mismatch;
            else
               return Tasking_Legality_Legal_Entry_Declaration;
            end if;

         when Tasking_Context_Entry_Body =>
            if not Context.Entry_Resolved then
               return Tasking_Legality_Entry_Missing;
            elsif Context.Entry_Duplicate then
               return Tasking_Legality_Entry_Duplicate;
            elsif not Context.Profile_Matches then
               return Tasking_Legality_Profile_Mismatch;
            elsif Context.Entry_Is_Family and then not Context.Entry_Family_Index_Resolved then
               return Tasking_Legality_Entry_Family_Index_Unresolved;
            elsif Context.Entry_Is_Family and then not Context.Entry_Family_Index_Compatible then
               return Tasking_Legality_Entry_Family_Index_Mismatch;
            elsif not Context.Barrier_Type_Resolved then
               return Tasking_Legality_Barrier_Unresolved;
            elsif not Context.Barrier_Is_Boolean then
               return Tasking_Legality_Barrier_Not_Boolean;
            else
               return Tasking_Legality_Legal_Entry_Body;
            end if;

         when Tasking_Context_Entry_Family =>
            if not Context.Entry_Family_Index_Resolved then
               return Tasking_Legality_Entry_Family_Index_Unresolved;
            elsif not Context.Entry_Family_Index_Compatible then
               return Tasking_Legality_Entry_Family_Index_Mismatch;
            elsif not Context.Entry_Family_Index_Static then
               return Tasking_Legality_Barrier_Non_Static_Family_Index;
            else
               return Tasking_Legality_Legal_Entry_Family;
            end if;

         when Tasking_Context_Accept_Statement =>
            if not Context.Accept_Is_In_Task_Body then
               return Tasking_Legality_Accept_Not_In_Task_Body;
            elsif not Context.Entry_Resolved then
               return Tasking_Legality_Accept_Entry_Missing;
            elsif not Context.Profile_Matches then
               return Tasking_Legality_Accept_Profile_Mismatch;
            else
               return Tasking_Legality_Legal_Accept;
            end if;

         when Tasking_Context_Requeue_Statement =>
            if not Context.Requeue_Target_Resolved then
               return Tasking_Legality_Requeue_Target_Unresolved;
            elsif not Context.Requeue_Target_Is_Entry then
               return Tasking_Legality_Requeue_To_Non_Entry;
            elsif not Context.Requeue_With_Abort_Allowed then
               return Tasking_Legality_Requeue_With_Abort_Not_Allowed;
            else
               return Tasking_Legality_Legal_Requeue;
            end if;

         when Tasking_Context_Protected_Function =>
            if Context.Protected_Function_Modifies_State then
               return Tasking_Legality_Protected_Function_Modifies_State;
            elsif Context.Protected_Function_Calls_Entry then
               return Tasking_Legality_Protected_Function_Calls_Entry;
            elsif not Context.Protected_Private_Data_Resolved then
               return Tasking_Legality_Protected_Private_Data_Unresolved;
            else
               return Tasking_Legality_Legal_Protected_Function;
            end if;

         when Tasking_Context_Protected_Procedure =>
            if Context.Protected_Procedure_Has_Barrier then
               return Tasking_Legality_Protected_Procedure_Barrier;
            elsif not Context.Protected_Private_Data_Resolved then
               return Tasking_Legality_Protected_Private_Data_Unresolved;
            else
               return Tasking_Legality_Legal_Protected_Procedure;
            end if;

         when Tasking_Context_Protected_Entry =>
            if not Context.Barrier_Present then
               return Tasking_Legality_Protected_Entry_Barrier_Missing;
            elsif not Context.Barrier_Type_Resolved then
               return Tasking_Legality_Barrier_Unresolved;
            elsif not Context.Barrier_Is_Boolean then
               return Tasking_Legality_Barrier_Not_Boolean;
            elsif not Context.Protected_Private_Data_Resolved then
               return Tasking_Legality_Protected_Private_Data_Unresolved;
            else
               return Tasking_Legality_Legal_Protected_Entry;
            end if;

         when Tasking_Context_Select_Statement =>
            if Context.Select_Has_Illegal_Alternative then
               return Tasking_Legality_Select_Alternative_Error;
            else
               return Tasking_Legality_Legal_Select;
            end if;

         when Tasking_Context_Unknown =>
            return Tasking_Legality_Indeterminate;
      end case;
   end Classify;

   function Make_Result
     (Context : Tasking_Context_Info;
      Id      : Tasking_Legality_Id;
      Status  : Tasking_Legality_Status) return Tasking_Legality_Info is
      Row : Tasking_Legality_Info;
   begin
      Row.Id := Id;
      Row.Context := Context.Id;
      Row.Kind := Context.Kind;
      Row.Node := Context.Node;
      Row.Spec_Node := Context.Spec_Node;
      Row.Body_Node := Context.Body_Node;
      Row.Entry_Node := Context.Entry_Node;
      Row.Barrier_Node := Context.Barrier_Node;
      Row.Status := Status;
      Row.Message := To_Unbounded_String (Message_For (Status));
      Row.Detail := To_Unbounded_String (Detail_For (Context, Status));
      Row.Normalized_Unit_Name := Context.Normalized_Unit_Name;
      Row.Normalized_Entry_Name := Context.Normalized_Entry_Name;
      Row.Flow_Legality := Context.Flow_Legality;
      Row.Start_Line := Context.Start_Line;
      Row.Start_Column := Context.Start_Column;
      Row.End_Line := Context.End_Line;
      Row.End_Column := Context.End_Column;
      Row.Source_Fingerprint := Context_Fingerprint (Context);
      Row.Fingerprint := Result_Fingerprint (Row);
      return Row;
   end Make_Result;

   procedure Clear (Model : in out Tasking_Context_Model) is
   begin
      Model.Contexts.Clear;
      Model.Fingerprint := 0;
   end Clear;

   procedure Add_Context
     (Model   : in out Tasking_Context_Model;
      Context : Tasking_Context_Info) is
      Copy : Tasking_Context_Info := Context;
   begin
      if Length (Copy.Normalized_Unit_Name) = 0 then
         Copy.Normalized_Unit_Name := Copy.Unit_Name;
      end if;
      if Length (Copy.Normalized_Entry_Name) = 0 then
         Copy.Normalized_Entry_Name := Copy.Entry_Name;
      end if;
      Copy.Fingerprint := Context_Fingerprint (Copy);
      Model.Contexts.Append (Copy);
      Model.Fingerprint := Mix (Model.Fingerprint, Copy.Fingerprint + 1);
   end Add_Context;

   function Context_Count (Model : Tasking_Context_Model) return Natural is
   begin
      return Natural (Model.Contexts.Length);
   end Context_Count;

   function Context_At
     (Model : Tasking_Context_Model;
      Index : Positive) return Tasking_Context_Info is
   begin
      return Model.Contexts.Element (Index);
   end Context_At;

   function Fingerprint (Model : Tasking_Context_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

   function Build
     (Contexts : Tasking_Context_Model;
      Flow     : Editor.Ada_Control_Flow_Legality.Flow_Legality_Model)
      return Tasking_Legality_Model is
      Model : Tasking_Legality_Model;
      Next  : Natural := 1;
   begin
      for Index in 1 .. Context_Count (Contexts) loop
         declare
            Context : constant Tasking_Context_Info := Context_At (Contexts, Index);
            Status  : constant Tasking_Legality_Status := Classify (Context, Flow);
            Row     : constant Tasking_Legality_Info :=
              Make_Result (Context, Tasking_Legality_Id (Next), Status);
         begin
            Model.Results.Append (Row);
            Model.Fingerprint := Mix (Model.Fingerprint, Row.Fingerprint + 1);
            Next := Next + 1;
         end;
      end loop;
      return Model;
   end Build;

   function Legality_Count (Model : Tasking_Legality_Model) return Natural is
   begin
      return Natural (Model.Results.Length);
   end Legality_Count;

   function Legality_At
     (Model : Tasking_Legality_Model;
      Index : Positive) return Tasking_Legality_Info is
   begin
      return Model.Results.Element (Index);
   end Legality_At;

   function First_For_Context
     (Model   : Tasking_Legality_Model;
      Context : Tasking_Context_Id) return Tasking_Legality_Info is
   begin
      for Row of Model.Results loop
         if Row.Context = Context then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Context;

   function First_For_Node
     (Model : Tasking_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Tasking_Legality_Info is
   begin
      for Row of Model.Results loop
         if Row.Node = Node then
            return Row;
         end if;
      end loop;
      return (others => <>);
   end First_For_Node;

   function Rows_For_Status
     (Model  : Tasking_Legality_Model;
      Status : Tasking_Legality_Status) return Tasking_Result_Set is
      Results : Tasking_Result_Set;
   begin
      for Row of Model.Results loop
         if Row.Status = Status then
            Results.Results.Append (Row);
         end if;
      end loop;
      return Results;
   end Rows_For_Status;

   function Rows_For_Kind
     (Model : Tasking_Legality_Model;
      Kind  : Tasking_Context_Kind) return Tasking_Result_Set is
      Results : Tasking_Result_Set;
   begin
      for Row of Model.Results loop
         if Row.Kind = Kind then
            Results.Results.Append (Row);
         end if;
      end loop;
      return Results;
   end Rows_For_Kind;

   function Rows_For_Unit
     (Model : Tasking_Legality_Model;
      Name  : Ada.Strings.Unbounded.Unbounded_String) return Tasking_Result_Set is
      Results : Tasking_Result_Set;
   begin
      for Row of Model.Results loop
         if Row.Normalized_Unit_Name = Name then
            Results.Results.Append (Row);
         end if;
      end loop;
      return Results;
   end Rows_For_Unit;

   function Rows_For_Entry
     (Model : Tasking_Legality_Model;
      Name  : Ada.Strings.Unbounded.Unbounded_String) return Tasking_Result_Set is
      Results : Tasking_Result_Set;
   begin
      for Row of Model.Results loop
         if Row.Normalized_Entry_Name = Name then
            Results.Results.Append (Row);
         end if;
      end loop;
      return Results;
   end Rows_For_Entry;

   function Result_Count (Results : Tasking_Result_Set) return Natural is
   begin
      return Natural (Results.Results.Length);
   end Result_Count;

   function Result_At
     (Results : Tasking_Result_Set;
      Index   : Positive) return Tasking_Legality_Info is
   begin
      return Results.Results.Element (Index);
   end Result_At;

   function Count_Status
     (Model  : Tasking_Legality_Model;
      Status : Tasking_Legality_Status) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Results loop
         if Row.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Count_Kind
     (Model : Tasking_Legality_Model;
      Kind  : Tasking_Context_Kind) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Results loop
         if Row.Kind = Kind then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Kind;

   function Compatible_Count (Model : Tasking_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Results loop
         if Is_Compatible (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Compatible_Count;

   function Error_Count (Model : Tasking_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Results loop
         if Is_Error (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Error_Count;

   function Warning_Count (Model : Tasking_Legality_Model) return Natural is
      Count : Natural := 0;
   begin
      for Row of Model.Results loop
         if Is_Warning (Row.Status) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Warning_Count;

   function Spec_Body_Error_Count (Model : Tasking_Legality_Model) return Natural is
   begin
      return Count_Status (Model, Tasking_Legality_Missing_Spec)
        + Count_Status (Model, Tasking_Legality_Missing_Body)
        + Count_Status (Model, Tasking_Legality_Duplicate_Body)
        + Count_Status (Model, Tasking_Legality_Kind_Mismatch)
        + Count_Status (Model, Tasking_Legality_Profile_Mismatch);
   end Spec_Body_Error_Count;

   function Entry_Error_Count (Model : Tasking_Legality_Model) return Natural is
   begin
      return Count_Status (Model, Tasking_Legality_Entry_Missing)
        + Count_Status (Model, Tasking_Legality_Entry_Duplicate)
        + Count_Status (Model, Tasking_Legality_Entry_Family_Index_Mismatch)
        + Count_Status (Model, Tasking_Legality_Entry_Family_Index_Unresolved)
        + Count_Status (Model, Tasking_Legality_Barrier_Non_Static_Family_Index);
   end Entry_Error_Count;

   function Barrier_Error_Count (Model : Tasking_Legality_Model) return Natural is
   begin
      return Count_Status (Model, Tasking_Legality_Barrier_Unresolved)
        + Count_Status (Model, Tasking_Legality_Barrier_Not_Boolean)
        + Count_Status (Model, Tasking_Legality_Protected_Entry_Barrier_Missing);
   end Barrier_Error_Count;

   function Accept_Requeue_Error_Count (Model : Tasking_Legality_Model) return Natural is
   begin
      return Count_Status (Model, Tasking_Legality_Accept_Entry_Missing)
        + Count_Status (Model, Tasking_Legality_Accept_Not_In_Task_Body)
        + Count_Status (Model, Tasking_Legality_Accept_Profile_Mismatch)
        + Count_Status (Model, Tasking_Legality_Requeue_Target_Unresolved)
        + Count_Status (Model, Tasking_Legality_Requeue_To_Non_Entry)
        + Count_Status (Model, Tasking_Legality_Requeue_With_Abort_Not_Allowed);
   end Accept_Requeue_Error_Count;

   function Protected_Operation_Error_Count (Model : Tasking_Legality_Model) return Natural is
   begin
      return Count_Status (Model, Tasking_Legality_Protected_Function_Modifies_State)
        + Count_Status (Model, Tasking_Legality_Protected_Function_Calls_Entry)
        + Count_Status (Model, Tasking_Legality_Protected_Procedure_Barrier)
        + Count_Status (Model, Tasking_Legality_Protected_Private_Data_Unresolved);
   end Protected_Operation_Error_Count;

   function Flow_Error_Count (Model : Tasking_Legality_Model) return Natural is
   begin
      return Count_Status (Model, Tasking_Legality_Flow_Legality_Error);
   end Flow_Error_Count;

   function Fingerprint (Model : Tasking_Legality_Model) return Natural is
   begin
      return Model.Fingerprint;
   end Fingerprint;

end Editor.Ada_Tasking_Protected_Legality;
