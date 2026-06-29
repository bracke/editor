with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Ada_Diagnostic_Action_Execution is

   package Commands renames Editor.Ada_Diagnostic_Command_Projection;
   use type Commands.Diagnostic_Command_Availability;
   use type Commands.Diagnostic_Command_Descriptor_Id;
   use type Commands.Diagnostic_Command_Kind;

   function Mix (A, B : Natural) return Natural is
      M : constant Long_Long_Integer := 1_000_000_007;
   begin
      return Natural
        ((Long_Long_Integer (A) * 131 + Long_Long_Integer (B) + 17) mod M);
   end Mix;

   function Effect_For
     (Kind : Commands.Diagnostic_Command_Kind)
      return Diagnostic_Action_Execution_Effect is
   begin
      case Kind is
         when Commands.Diagnostic_Command_Navigate_To_Diagnostic =>
            return Diagnostic_Action_Effect_Navigate;
         when Commands.Diagnostic_Command_Explain_Diagnostic =>
            return Diagnostic_Action_Effect_Explain;
         when Commands.Diagnostic_Command_Review_Expression =>
            return Diagnostic_Action_Effect_Review_Expression;
         when Commands.Diagnostic_Command_Review_Overload_Ranking =>
            return Diagnostic_Action_Effect_Review_Overload_Ranking;
         when Commands.Diagnostic_Command_Review_Generic =>
            return Diagnostic_Action_Effect_Review_Generic;
         when Commands.Diagnostic_Command_Review_Cross_Unit =>
            return Diagnostic_Action_Effect_Review_Cross_Unit;
         when Commands.Diagnostic_Command_Review_Representation =>
            return Diagnostic_Action_Effect_Review_Representation;
         when Commands.Diagnostic_Command_None =>
            return Diagnostic_Action_Effect_None;
      end case;
   end Effect_For;

   function Status_For
     (Availability : Commands.Diagnostic_Command_Availability)
      return Diagnostic_Action_Execution_Status is
   begin
      case Availability is
         when Commands.Diagnostic_Command_Available =>
            return Diagnostic_Action_Execution_Executed;
         when Commands.Diagnostic_Command_Rejected_Stale =>
            return Diagnostic_Action_Execution_Rejected_Stale;
         when Commands.Diagnostic_Command_Missing_Target
            | Commands.Diagnostic_Command_Incomplete_Target
            | Commands.Diagnostic_Command_Status_Only =>
            return Diagnostic_Action_Execution_Unavailable;
      end case;
   end Status_For;

   function Is_Executable
     (Descriptor : Diagnostic_Command_Descriptor) return Boolean is
   begin
      return Descriptor.Id /= Commands.No_Diagnostic_Command_Descriptor
        and then Descriptor.Availability = Commands.Diagnostic_Command_Available
        and then Descriptor.Command_Kind /= Commands.Diagnostic_Command_None;
   end Is_Executable;

   function Execute
     (Descriptor : Diagnostic_Command_Descriptor)
      return Diagnostic_Action_Execution_Result
   is
      Result : Diagnostic_Action_Execution_Result;
      Edit_Fingerprint : constant Natural :=
        Mix
          (Boolean'Pos (Descriptor.Has_Edit),
           Mix
             (Descriptor.Edit_Start_Line,
              Mix
                (Descriptor.Edit_Start_Column,
                 Mix
                   (Descriptor.Edit_End_Line,
                    Mix
                      (Descriptor.Edit_End_Column,
                       Length (Descriptor.Replacement_Text) + 1)))));
   begin
      Result.Descriptor_Id := Descriptor.Id;
      Result.Status := Status_For (Descriptor.Availability);
      Result.Start_Line := Descriptor.Start_Line;
      Result.Start_Column := Descriptor.Start_Column;
      Result.End_Line := Descriptor.End_Line;
      Result.End_Column := Descriptor.End_Column;
      Result.Has_Edit := Descriptor.Has_Edit;
      Result.Edit_Start_Line := Descriptor.Edit_Start_Line;
      Result.Edit_Start_Column := Descriptor.Edit_Start_Column;
      Result.Edit_End_Line := Descriptor.Edit_End_Line;
      Result.Edit_End_Column := Descriptor.Edit_End_Column;
      Result.Replacement_Text := Descriptor.Replacement_Text;

      if Is_Executable (Descriptor) then
         if Descriptor.Has_Edit then
            Result.Effect := Diagnostic_Action_Effect_Edit;
         else
            Result.Effect := Effect_For (Descriptor.Command_Kind);
         end if;
         Result.Message := Descriptor.Display_Label;
      elsif Descriptor.Availability = Commands.Diagnostic_Command_Rejected_Stale then
         Result.Effect := Diagnostic_Action_Effect_None;
         Result.Message := To_Unbounded_String ("Diagnostic action rejected: stale snapshot");
      else
         Result.Effect := Diagnostic_Action_Effect_None;
         Result.Message := To_Unbounded_String ("Diagnostic action unavailable");
      end if;

      Result.Fingerprint :=
        Mix
          (Mix
             (Natural (Descriptor.Id),
              Commands.Diagnostic_Command_Kind'Pos (Descriptor.Command_Kind)),
           Mix
             (Commands.Diagnostic_Command_Availability'Pos
                (Descriptor.Availability),
              Mix (Descriptor.Fingerprint, Edit_Fingerprint)));
      return Result;
   end Execute;

   procedure Append_Result
     (Results : in out Diagnostic_Action_Execution_Result_Set;
      Result  : Diagnostic_Action_Execution_Result)
   is
   begin
      Results.Results.Append (Result);
      case Result.Status is
         when Diagnostic_Action_Execution_Executed =>
            Results.Executed_Total := Results.Executed_Total + 1;
            if Result.Has_Edit then
               Results.Editable_Total := Results.Editable_Total + 1;
            end if;
         when Diagnostic_Action_Execution_Rejected_Stale =>
            Results.Rejected_Total := Results.Rejected_Total + 1;
         when Diagnostic_Action_Execution_Unavailable =>
            Results.Unavailable_Total := Results.Unavailable_Total + 1;
      end case;
      Results.Result_Fingerprint :=
        Mix (Results.Result_Fingerprint, Result.Fingerprint + 1);
   end Append_Result;

   function Execute_All
     (Model : Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Projection_Model)
      return Diagnostic_Action_Execution_Result_Set
   is
      Results : Diagnostic_Action_Execution_Result_Set;
   begin
      for I in 1 .. Commands.Descriptor_Count (Model) loop
         Append_Result (Results, Execute (Commands.Descriptor_At (Model, I)));
      end loop;
      return Results;
   end Execute_All;

   function Execute_All
     (Descriptors : Diagnostic_Command_Descriptor_Array)
      return Diagnostic_Action_Execution_Result_Set
   is
      Results : Diagnostic_Action_Execution_Result_Set;
   begin
      for Descriptor of Descriptors loop
         Append_Result (Results, Execute (Descriptor));
      end loop;
      return Results;
   end Execute_All;

   function Result_Count
     (Results : Diagnostic_Action_Execution_Result_Set) return Natural is
   begin
      return Natural (Results.Results.Length);
   end Result_Count;

   function Result_At
     (Results : Diagnostic_Action_Execution_Result_Set;
      Index   : Positive) return Diagnostic_Action_Execution_Result is
   begin
      if Index > Natural (Results.Results.Length) then
         return (others => <>);
      end if;
      return Results.Results.Element (Index);
   end Result_At;

   function Executed_Count
     (Results : Diagnostic_Action_Execution_Result_Set) return Natural is
   begin
      return Results.Executed_Total;
   end Executed_Count;

   function Rejected_Stale_Count
     (Results : Diagnostic_Action_Execution_Result_Set) return Natural is
   begin
      return Results.Rejected_Total;
   end Rejected_Stale_Count;

   function Unavailable_Count
     (Results : Diagnostic_Action_Execution_Result_Set) return Natural is
   begin
      return Results.Unavailable_Total;
   end Unavailable_Count;

   function Editable_Count
     (Results : Diagnostic_Action_Execution_Result_Set) return Natural is
   begin
      return Results.Editable_Total;
   end Editable_Count;

   function First_Success
     (Results : Diagnostic_Action_Execution_Result_Set)
      return Diagnostic_Action_Execution_Result is
   begin
      for Result of Results.Results loop
         if Is_Success (Result) then
            return Result;
         end if;
      end loop;
      return (others => <>);
   end First_Success;

   function Fingerprint
     (Results : Diagnostic_Action_Execution_Result_Set) return Natural is
   begin
      return Results.Result_Fingerprint;
   end Fingerprint;

   function Is_Success
     (Result : Diagnostic_Action_Execution_Result) return Boolean is
   begin
      return Result.Status = Diagnostic_Action_Execution_Executed
        and then Result.Effect /= Diagnostic_Action_Effect_None;
   end Is_Success;

end Editor.Ada_Diagnostic_Action_Execution;
