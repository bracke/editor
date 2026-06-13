with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Build_Result_Summary is

   function Empty_Summary return Latest_Build_Result_Summary is
   begin
      return (others => <>);
   end Empty_Summary;

   function Retain_Pre_Run_Unavailable_Summary return Boolean is
   begin
      return True;
   end Retain_Pre_Run_Unavailable_Summary;

   function Canonicalize_Latest_Build_Result_Summary
     (Summary : Latest_Build_Result_Summary)
      return Latest_Build_Result_Summary
   is
      Result : Latest_Build_Result_Summary := Summary;
   begin
      if not Result.Has_Result then
         return Empty_Summary;
      end if;

      if Result.Kind = Build_Result_Summary_None then
         Result.Has_Result := False;
         return Empty_Summary;
      end if;

      if not Result.Has_Exit_Code then
         Result.Exit_Code_If_Available := 0;
      end if;

      if not Result.Has_Diagnostics_Count then
         Result.Diagnostics_Count_If_Available := 0;
      end if;

      if not Result.Has_Diagnostics_Severity_Counts then
         Result.Diagnostics_Error_Count := 0;
         Result.Diagnostics_Warning_Count := 0;
         Result.Diagnostics_Info_Count := 0;
         Result.Diagnostics_Note_Count := 0;
         Result.Diagnostics_Unknown_Count := 0;
      end if;

      if Result.Diagnostics_Ingestion_Status = Diagnostics_Ingestion_Succeeded
        and then Result.Has_Diagnostics_Count
        and then Result.Diagnostics_Count_If_Available = 0
      then
         Result.Diagnostics_Ingestion_Status := Diagnostics_Ingestion_No_Diagnostics;
      elsif Result.Diagnostics_Ingestion_Status = Diagnostics_Ingestion_Parse_Partial
        and then ((not Result.Has_Diagnostics_Count)
                  or else Result.Diagnostics_Count_If_Available = 0)
      then
         Result.Diagnostics_Ingestion_Status := Diagnostics_Ingestion_Failed;
      end if;

      if Result.Diagnostics_Ingestion_Status in
        Diagnostics_Ingestion_Not_Requested | Diagnostics_Ingestion_Disabled |
        Diagnostics_Ingestion_Failed
      then
         Result.Has_Diagnostics_Count := False;
         Result.Diagnostics_Count_If_Available := 0;
         Result.Has_Diagnostics_Severity_Counts := False;
         Result.Diagnostics_Error_Count := 0;
         Result.Diagnostics_Warning_Count := 0;
         Result.Diagnostics_Info_Count := 0;
         Result.Diagnostics_Note_Count := 0;
         Result.Diagnostics_Unknown_Count := 0;
      elsif Result.Diagnostics_Ingestion_Status = Diagnostics_Ingestion_No_Diagnostics then
         Result.Has_Diagnostics_Count := True;
         Result.Diagnostics_Count_If_Available := 0;
         Result.Has_Diagnostics_Severity_Counts := False;
         Result.Diagnostics_Error_Count := 0;
         Result.Diagnostics_Warning_Count := 0;
         Result.Diagnostics_Info_Count := 0;
         Result.Diagnostics_Note_Count := 0;
         Result.Diagnostics_Unknown_Count := 0;
      end if;

      --  Phase 527 distinction: truncation means an output stream exceeded a
      --  configured bound; partial means capture ended early because the
      --  invocation timed out or was cancelled.  Do not conflate them.
      Result.Output_Partial :=
        Result.Output_Partial or else
        Result.Timed_Out or else
        Result.Cancelled;

      return Result;
   end Canonicalize_Latest_Build_Result_Summary;

   function Clear_Stale_Build_Result_Summary_Fields
     (Summary : Latest_Build_Result_Summary)
      return Latest_Build_Result_Summary
   is
   begin
      return Canonicalize_Latest_Build_Result_Summary (Summary);
   end Clear_Stale_Build_Result_Summary_Fields;

   function Replace_Latest_Build_Result_Summary
     (Current : Latest_Build_Result_Summary;
      Next    : Latest_Build_Result_Summary)
      return Latest_Build_Result_Summary
   is
      pragma Unreferenced (Current);
   begin
      return Canonicalize_Latest_Build_Result_Summary (Next);
   end Replace_Latest_Build_Result_Summary;

   function Build_Summary
     (Kind           : Build_Result_Summary_Kind;
      Invocation_Label : String;
      Tool_Kind      : Build_Result_Tool_Kind;
      Request_Mode   : Build_Result_Request_Mode;
      Working_Context_Label : String;
      Runner_Status_Label : String;
      Primary_Message : String;
      Exit_Code       : Integer := 0;
      Has_Exit_Code   : Boolean := False;
      Timed_Out       : Boolean := False;
      Cancelled       : Boolean := False;
      Cancellation_Unsupported : Boolean := False;
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Output_Partial   : Boolean := False;
      Diagnostics_Ingestion_Status : Diagnostics_Ingestion_Summary_Status :=
        Diagnostics_Ingestion_Not_Requested;
      Diagnostics_Count : Natural := 0;
      Has_Diagnostics_Count : Boolean := False;
      Diagnostics_Error_Count : Natural := 0;
      Diagnostics_Warning_Count : Natural := 0;
      Diagnostics_Info_Count : Natural := 0;
      Diagnostics_Note_Count : Natural := 0;
      Diagnostics_Unknown_Count : Natural := 0;
      Has_Diagnostics_Severity_Counts : Boolean := False)
      return Latest_Build_Result_Summary
   is
   begin
      return Canonicalize_Latest_Build_Result_Summary
        ((Has_Result => True,
         Kind => Kind,
         Invocation_Label => To_Unbounded_String (Invocation_Label),
         Tool_Kind => Tool_Kind,
         Request_Mode => Request_Mode,
         Working_Context_Label => To_Unbounded_String (Working_Context_Label),
         Runner_Status_Label => To_Unbounded_String (Runner_Status_Label),
         Exit_Code_If_Available => Exit_Code,
         Has_Exit_Code => Has_Exit_Code,
         Timed_Out => Timed_Out,
         Cancelled => Cancelled,
         Cancellation_Unsupported => Cancellation_Unsupported,
         Stdout_Truncated => Stdout_Truncated,
         Stderr_Truncated => Stderr_Truncated,
         Output_Partial => Output_Partial or else Timed_Out or else Cancelled,
         Diagnostics_Ingestion_Status => Diagnostics_Ingestion_Status,
         Diagnostics_Count_If_Available => Diagnostics_Count,
         Has_Diagnostics_Count => Has_Diagnostics_Count,
         Diagnostics_Error_Count => Diagnostics_Error_Count,
         Diagnostics_Warning_Count => Diagnostics_Warning_Count,
         Diagnostics_Info_Count => Diagnostics_Info_Count,
         Diagnostics_Note_Count => Diagnostics_Note_Count,
         Diagnostics_Unknown_Count => Diagnostics_Unknown_Count,
         Has_Diagnostics_Severity_Counts => Has_Diagnostics_Severity_Counts,
         Primary_Message => To_Unbounded_String (Primary_Message)));
   end Build_Summary;

   function Summary_From_Unavailable_Message
     (Message : String) return Latest_Build_Result_Summary
   is
   begin
      return Build_Summary
        (Kind => Build_Result_Summary_Unavailable,
         Invocation_Label => "build.run",
         Tool_Kind => Build_Result_No_Tool,
         Request_Mode => Build_Result_Request_None,
         Working_Context_Label => "",
         Runner_Status_Label => "not available",
         Primary_Message => Message,
         Diagnostics_Ingestion_Status => Diagnostics_Ingestion_Not_Requested);
   end Summary_From_Unavailable_Message;

   function Status_Label (Summary : Latest_Build_Result_Summary) return String is
   begin
      if not Summary.Has_Result then
         return "No build result yet.";
      end if;
      case Summary.Kind is
         when Build_Result_Summary_None => return "No build result yet.";
         when Build_Result_Summary_Succeeded => return "Build succeeded";
         when Build_Result_Summary_Failed => return "Build failed";
         when Build_Result_Summary_Unavailable => return "Build unavailable: check the Build panel run availability reason.";
         when Build_Result_Summary_Timed_Out => return "Build timed out";
         when Build_Result_Summary_Cancelled => return "Build cancelled";
         when Build_Result_Summary_Output_Truncated => return "Build output truncated";
      end case;
   end Status_Label;

   function Tool_Label (Summary : Latest_Build_Result_Summary) return String is
   begin
      case Summary.Tool_Kind is
         when Build_Result_GPRbuild_Tool => return "gprbuild";
         when Build_Result_Alire_Tool => return "alire";
         when Build_Result_Custom_Tool => return "custom";
         when Build_Result_No_Tool => return "no tool";
      end case;
   end Tool_Label;

   function Working_Context_Label
     (Summary : Latest_Build_Result_Summary) return String is
   begin
      if Length (Summary.Working_Context_Label) = 0 then
         return "no project working context";
      end if;
      return To_String (Summary.Working_Context_Label);
   end Working_Context_Label;

   function Exit_Code_Label (Summary : Latest_Build_Result_Summary) return String is
   begin
      if Summary.Has_Exit_Code then
         return Integer'Image (Summary.Exit_Code_If_Available);
      end if;
      return "exit code unavailable";
   end Exit_Code_Label;

   function Timeout_Label (Summary : Latest_Build_Result_Summary) return String is
   begin
      if Summary.Timed_Out then
         return "timed out";
      end if;
      return "not timed out";
   end Timeout_Label;

   function Cancellation_Label
     (Summary : Latest_Build_Result_Summary) return String is
   begin
      if Summary.Cancelled then
         return "cancelled";
      elsif Summary.Cancellation_Unsupported then
         return "cancellation unsupported";
      end if;
      return "not cancelled";
   end Cancellation_Label;

   function Truncation_Label
     (Summary : Latest_Build_Result_Summary) return String is
   begin
      if Summary.Stdout_Truncated and then Summary.Stderr_Truncated then
         return "stdout truncated; stderr truncated";
      elsif Summary.Stdout_Truncated then
         return "stdout truncated";
      elsif Summary.Stderr_Truncated then
         return "stderr truncated";
      end if;
      return "output not truncated";
   end Truncation_Label;

   function Partial_Output_Label
     (Summary : Latest_Build_Result_Summary) return String is
   begin
      if Summary.Timed_Out then
         return "build timed out; output may be incomplete";
      elsif Summary.Cancelled then
         return "build cancelled; output may be incomplete";
      elsif Summary.Output_Partial
        and then not Summary.Stdout_Truncated
        and then not Summary.Stderr_Truncated
      then
         return "Partial output captured";
      end if;
      return "output complete within captured bounds";
   end Partial_Output_Label;

   function Diagnostics_Label
     (Summary : Latest_Build_Result_Summary) return String is
   begin
      case Summary.Diagnostics_Ingestion_Status is
         when Diagnostics_Ingestion_Not_Requested =>
            return "Diagnostics not requested.";
         when Diagnostics_Ingestion_Disabled =>
            return "Diagnostics ingestion disabled.";
         when Diagnostics_Ingestion_Succeeded =>
            if Summary.Has_Diagnostics_Count then
               if Summary.Diagnostics_Count_If_Available = 0 then
                  return "No diagnostics.";
               else
                  if Summary.Has_Diagnostics_Severity_Counts then
                     return "Diagnostics produced:" & Natural'Image
                       (Summary.Diagnostics_Count_If_Available)
                       & " (errors" & Natural'Image (Summary.Diagnostics_Error_Count)
                       & ", warnings" & Natural'Image (Summary.Diagnostics_Warning_Count)
                       & ", info" & Natural'Image (Summary.Diagnostics_Info_Count)
                       & ", notes" & Natural'Image (Summary.Diagnostics_Note_Count)
                       & ", unknown" & Natural'Image (Summary.Diagnostics_Unknown_Count)
                       & ")";
                  else
                     return "Diagnostics produced:" & Natural'Image
                       (Summary.Diagnostics_Count_If_Available);
                  end if;
               end if;
            else
               return "Diagnostics produced";
            end if;
         when Diagnostics_Ingestion_No_Diagnostics =>
            return "No diagnostics.";
         when Diagnostics_Ingestion_Parse_Partial =>
            return "Diagnostics parsed partially; review output for details.";
         when Diagnostics_Ingestion_Failed =>
            return "Diagnostics ingestion failed; review output for details.";
      end case;
   end Diagnostics_Label;

   function Render_Snapshot
     (Summary : Latest_Build_Result_Summary)
      return Latest_Build_Result_Render_Snapshot
   is
   begin
      if not Summary.Has_Result then
         return (others => <>);
      end if;

      return
        (Latest_Build_Result_Visible => True,
         Latest_Build_Result_Status_Label =>
           To_Unbounded_String (Status_Label (Summary)),
         Latest_Build_Result_Tool_Label =>
           To_Unbounded_String (Tool_Label (Summary)),
         Latest_Build_Result_Runner_Status_Label =>
           Summary.Runner_Status_Label,
         Latest_Build_Result_Working_Context_Label =>
           To_Unbounded_String (Working_Context_Label (Summary)),
         Latest_Build_Result_Exit_Code_Label =>
           To_Unbounded_String (Exit_Code_Label (Summary)),
         Latest_Build_Result_Timeout_Label =>
           To_Unbounded_String (Timeout_Label (Summary)),
         Latest_Build_Result_Cancellation_Label =>
           To_Unbounded_String (Cancellation_Label (Summary)),
         Latest_Build_Result_Truncation_Label =>
           To_Unbounded_String (Truncation_Label (Summary)),
         Latest_Build_Result_Partial_Output_Label =>
           To_Unbounded_String (Partial_Output_Label (Summary)),
         Latest_Build_Result_Diagnostics_Label =>
           To_Unbounded_String (Diagnostics_Label (Summary)),
         Latest_Build_Result_Primary_Message_Label =>
           Summary.Primary_Message);
   end Render_Snapshot;

   function Has_Process_Handle_Field
     (Summary : Latest_Build_Result_Summary) return Boolean is
      pragma Unreferenced (Summary);
   begin
      return False;
   end Has_Process_Handle_Field;

   function Has_Cancellation_Token_Field
     (Summary : Latest_Build_Result_Summary) return Boolean is
      pragma Unreferenced (Summary);
   begin
      return False;
   end Has_Cancellation_Token_Field;

   function Has_Rerun_Request_Payload_Field
     (Summary : Latest_Build_Result_Summary) return Boolean is
      pragma Unreferenced (Summary);
   begin
      return False;
   end Has_Rerun_Request_Payload_Field;

   function Has_Diagnostics_Rows_Field
     (Summary : Latest_Build_Result_Summary) return Boolean is
      pragma Unreferenced (Summary);
   begin
      return False;
   end Has_Diagnostics_Rows_Field;

   function Has_Unbounded_Output_Field
     (Summary : Latest_Build_Result_Summary) return Boolean is
      pragma Unreferenced (Summary);
   begin
      return False;
   end Has_Unbounded_Output_Field;

   function Has_Build_History_Field
     (Summary : Latest_Build_Result_Summary) return Boolean is
      pragma Unreferenced (Summary);
   begin
      return False;
   end Has_Build_History_Field;

   function Has_Consent_Field
     (Summary : Latest_Build_Result_Summary) return Boolean is
      pragma Unreferenced (Summary);
   begin
      return False;
   end Has_Consent_Field;

   function Has_Full_Stdout_Field
     (Summary : Latest_Build_Result_Summary) return Boolean is
      pragma Unreferenced (Summary);
   begin
      return False;
   end Has_Full_Stdout_Field;

   function Has_Full_Stderr_Field
     (Summary : Latest_Build_Result_Summary) return Boolean is
      pragma Unreferenced (Summary);
   begin
      return False;
   end Has_Full_Stderr_Field;

   function Has_Diagnostics_Table_Field
     (Summary : Latest_Build_Result_Summary) return Boolean is
      pragma Unreferenced (Summary);
   begin
      return False;
   end Has_Diagnostics_Table_Field;

   function Has_Runner_UI_Result_Field
     (Summary : Latest_Build_Result_Summary) return Boolean is
      pragma Unreferenced (Summary);
   begin
      return False;
   end Has_Runner_UI_Result_Field;

   function Has_Persistence_Field
     (Summary : Latest_Build_Result_Summary) return Boolean is
      pragma Unreferenced (Summary);
   begin
      return False;
   end Has_Persistence_Field;

   function Summary_Can_Be_Converted_To_Public_Build_Request
     (Summary : Latest_Build_Result_Summary) return Boolean is
      pragma Unreferenced (Summary);
   begin
      return False;
   end Summary_Can_Be_Converted_To_Public_Build_Request;

   function Assert_Latest_Build_Result_Summary_Owned_By_Executor
     (Summary : Latest_Build_Result_Summary) return Boolean is
      pragma Unreferenced (Summary);
   begin
      return True;
   end Assert_Latest_Build_Result_Summary_Owned_By_Executor;

   function Assert_Latest_Build_Result_Summary_Shape_Canonical
     (Summary : Latest_Build_Result_Summary) return Boolean
   is
      Canonical : constant Latest_Build_Result_Summary :=
        Canonicalize_Latest_Build_Result_Summary (Summary);
   begin
      return Canonical.Has_Result = Summary.Has_Result
        and then Canonical.Kind = Summary.Kind
        and then Canonical.Has_Exit_Code = Summary.Has_Exit_Code
        and then Canonical.Exit_Code_If_Available = Summary.Exit_Code_If_Available
        and then Canonical.Has_Diagnostics_Count = Summary.Has_Diagnostics_Count
        and then Canonical.Diagnostics_Count_If_Available =
          Summary.Diagnostics_Count_If_Available
        and then Canonical.Output_Partial = Summary.Output_Partial;
   end Assert_Latest_Build_Result_Summary_Shape_Canonical;

   function Assert_Latest_Build_Result_Summary_Replace_Only
     (Before : Latest_Build_Result_Summary;
      After  : Latest_Build_Result_Summary) return Boolean
   is
      Replaced : constant Latest_Build_Result_Summary :=
        Replace_Latest_Build_Result_Summary (Before, After);
      Canonical_After : constant Latest_Build_Result_Summary :=
        Canonicalize_Latest_Build_Result_Summary (After);
   begin
      return Replaced.Has_Result = Canonical_After.Has_Result
        and then Replaced.Kind = Canonical_After.Kind
        and then Replaced.Tool_Kind = Canonical_After.Tool_Kind
        and then Replaced.Request_Mode = Canonical_After.Request_Mode
        and then Replaced.Has_Exit_Code = Canonical_After.Has_Exit_Code
        and then Replaced.Exit_Code_If_Available =
          Canonical_After.Exit_Code_If_Available
        and then Replaced.Timed_Out = Canonical_After.Timed_Out
        and then Replaced.Cancelled = Canonical_After.Cancelled
        and then Replaced.Stdout_Truncated = Canonical_After.Stdout_Truncated
        and then Replaced.Stderr_Truncated = Canonical_After.Stderr_Truncated
        and then Replaced.Has_Diagnostics_Count =
          Canonical_After.Has_Diagnostics_Count
        and then Replaced.Diagnostics_Count_If_Available =
          Canonical_After.Diagnostics_Count_If_Available;
   end Assert_Latest_Build_Result_Summary_Replace_Only;

   function Assert_Latest_Build_Result_Summary_Not_Rerun_State
     (Summary : Latest_Build_Result_Summary) return Boolean is
   begin
      return not Has_Rerun_Request_Payload_Field (Summary)
        and then not Has_Consent_Field (Summary)
        and then not Summary_Can_Be_Converted_To_Public_Build_Request (Summary);
   end Assert_Latest_Build_Result_Summary_Not_Rerun_State;

   function Assert_Latest_Build_Result_Summary_Not_Diagnostics_Owner
     (Summary : Latest_Build_Result_Summary) return Boolean is
   begin
      return not Has_Diagnostics_Rows_Field (Summary)
        and then not Has_Diagnostics_Table_Field (Summary);
   end Assert_Latest_Build_Result_Summary_Not_Diagnostics_Owner;

   function Assert_Latest_Build_Result_Summary_Not_Output_Log
     (Summary : Latest_Build_Result_Summary) return Boolean is
   begin
      return not Has_Full_Stdout_Field (Summary)
        and then not Has_Full_Stderr_Field (Summary)
        and then not Has_Unbounded_Output_Field (Summary);
   end Assert_Latest_Build_Result_Summary_Not_Output_Log;

   function Assert_Latest_Build_Result_Summary_Render_Cleanup
     (Summary : Latest_Build_Result_Summary) return Boolean is
      Snapshot : constant Latest_Build_Result_Render_Snapshot :=
        Render_Snapshot (Summary);
      pragma Unreferenced (Snapshot);
   begin
      return Assert_Latest_Build_Result_Summary_Shape_Canonical (Summary)
        and then not Has_Runner_UI_Result_Field (Summary);
   end Assert_Latest_Build_Result_Summary_Render_Cleanup;

   function Assert_Latest_Build_Result_Summary_Persistence_Excluded
     (Summary : Latest_Build_Result_Summary) return Boolean is
   begin
      return not Has_Persistence_Field (Summary)
        and then not Has_Build_History_Field (Summary);
   end Assert_Latest_Build_Result_Summary_Persistence_Excluded;

   function Assert_Summary_Is_Transient_Projection
     (Summary : Latest_Build_Result_Summary) return Boolean
   is
   begin
      return Assert_Latest_Build_Result_Summary_Shape_Canonical (Summary)
        and then not Has_Process_Handle_Field (Summary)
        and then not Has_Cancellation_Token_Field (Summary)
        and then Assert_Latest_Build_Result_Summary_Not_Rerun_State (Summary)
        and then Assert_Latest_Build_Result_Summary_Not_Diagnostics_Owner (Summary)
        and then Assert_Latest_Build_Result_Summary_Not_Output_Log (Summary)
        and then Assert_Latest_Build_Result_Summary_Persistence_Excluded (Summary);
   end Assert_Summary_Is_Transient_Projection;

   function Assert_Public_Build_Result_Surface_Canonical_Coherent
     (Summary : Latest_Build_Result_Summary) return Boolean
   is
   begin
      return Assert_Latest_Build_Result_Summary_Owned_By_Executor (Summary)
        and then Assert_Summary_Is_Transient_Projection (Summary)
        and then Assert_Latest_Build_Result_Summary_Render_Cleanup (Summary);
   end Assert_Public_Build_Result_Surface_Canonical_Coherent;


   function Assert_Latest_Build_Result_Summary_Final_Ownership_Frozen
     (Summary : Latest_Build_Result_Summary) return Boolean is
   begin
      return Assert_Latest_Build_Result_Summary_Owned_By_Executor (Summary)
        and then not Has_Runner_UI_Result_Field (Summary)
        and then not Has_Persistence_Field (Summary);
   end Assert_Latest_Build_Result_Summary_Final_Ownership_Frozen;

   function Assert_Latest_Build_Result_Summary_Final_Shape_Frozen
     (Summary : Latest_Build_Result_Summary) return Boolean is
   begin
      return Assert_Latest_Build_Result_Summary_Shape_Canonical (Summary)
        and then not Has_Process_Handle_Field (Summary)
        and then not Has_Cancellation_Token_Field (Summary)
        and then not Has_Rerun_Request_Payload_Field (Summary)
        and then not Has_Consent_Field (Summary)
        and then not Has_Full_Stdout_Field (Summary)
        and then not Has_Full_Stderr_Field (Summary)
        and then not Has_Unbounded_Output_Field (Summary)
        and then not Has_Diagnostics_Rows_Field (Summary)
        and then not Has_Diagnostics_Table_Field (Summary)
        and then not Has_Build_History_Field (Summary)
        and then not Has_Persistence_Field (Summary);
   end Assert_Latest_Build_Result_Summary_Final_Shape_Frozen;

   function Assert_Latest_Build_Result_Summary_Final_Mapping_Frozen
     (Summary : Latest_Build_Result_Summary) return Boolean
   is
      Diagnostics_Count_Allowed : constant Boolean :=
        (if Summary.Diagnostics_Ingestion_Status in
            Diagnostics_Ingestion_Succeeded | Diagnostics_Ingestion_Parse_Partial
         then Summary.Has_Diagnostics_Count
              and then Summary.Diagnostics_Count_If_Available > 0
         elsif Summary.Diagnostics_Ingestion_Status = Diagnostics_Ingestion_No_Diagnostics
         then Summary.Has_Diagnostics_Count
              and then Summary.Diagnostics_Count_If_Available = 0
         else (not Summary.Has_Diagnostics_Count)
              and then Summary.Diagnostics_Count_If_Available = 0);
   begin
      if not Assert_Latest_Build_Result_Summary_Final_Shape_Frozen (Summary) then
         return False;
      end if;

      if not Summary.Has_Result then
         return Summary.Kind = Build_Result_Summary_None
           and then not Summary.Has_Exit_Code
           and then not Summary.Timed_Out
           and then not Summary.Cancelled
           and then not Summary.Cancellation_Unsupported
           and then not Summary.Output_Partial
           and then Diagnostics_Count_Allowed;
      end if;

      if not Diagnostics_Count_Allowed then
         return False;
      end if;

      case Summary.Kind is
         when Build_Result_Summary_None =>
            return False;
         when Build_Result_Summary_Succeeded =>
            return not Summary.Timed_Out
              and then not Summary.Cancelled
              and then not Summary.Cancellation_Unsupported;
         when Build_Result_Summary_Failed =>
            return not Summary.Timed_Out
              and then not Summary.Cancelled
              and then not Summary.Cancellation_Unsupported;
         when Build_Result_Summary_Unavailable =>
            return not Summary.Timed_Out
              and then not Summary.Cancelled
              and then not Summary.Stdout_Truncated
              and then not Summary.Stderr_Truncated
              and then not Summary.Output_Partial;
         when Build_Result_Summary_Timed_Out =>
            return Summary.Timed_Out and then not Summary.Cancelled;
         when Build_Result_Summary_Cancelled =>
            return Summary.Cancelled and then not Summary.Timed_Out;
         when Build_Result_Summary_Output_Truncated =>
            return (Summary.Stdout_Truncated or else Summary.Stderr_Truncated);
      end case;
   end Assert_Latest_Build_Result_Summary_Final_Mapping_Frozen;

   function Assert_Latest_Build_Result_Summary_Final_Replace_Only_Frozen
     (Before : Latest_Build_Result_Summary;
      After  : Latest_Build_Result_Summary) return Boolean
   is
      Replaced : constant Latest_Build_Result_Summary :=
        Replace_Latest_Build_Result_Summary (Before, After);
   begin
      return Assert_Latest_Build_Result_Summary_Replace_Only (Before, After)
        and then Assert_Latest_Build_Result_Summary_Final_Mapping_Frozen (Replaced)
        and then not Has_Build_History_Field (Replaced);
   end Assert_Latest_Build_Result_Summary_Final_Replace_Only_Frozen;

   function Assert_Latest_Build_Result_Summary_Final_No_History
     (Summary : Latest_Build_Result_Summary) return Boolean is
   begin
      return not Has_Build_History_Field (Summary)
        and then Assert_Latest_Build_Result_Summary_Final_Shape_Frozen (Summary);
   end Assert_Latest_Build_Result_Summary_Final_No_History;

   function Assert_Latest_Build_Result_Summary_Final_Not_Rerun_State
     (Summary : Latest_Build_Result_Summary) return Boolean is
   begin
      return Assert_Latest_Build_Result_Summary_Not_Rerun_State (Summary)
        and then not Summary_Can_Be_Converted_To_Public_Build_Request (Summary);
   end Assert_Latest_Build_Result_Summary_Final_Not_Rerun_State;

   function Assert_Latest_Build_Result_Summary_Final_Not_Process_Control
     (Summary : Latest_Build_Result_Summary) return Boolean is
   begin
      return not Has_Process_Handle_Field (Summary)
        and then not Has_Cancellation_Token_Field (Summary);
   end Assert_Latest_Build_Result_Summary_Final_Not_Process_Control;

   function Assert_Latest_Build_Result_Summary_Final_Not_Output_Log
     (Summary : Latest_Build_Result_Summary) return Boolean is
   begin
      return Assert_Latest_Build_Result_Summary_Not_Output_Log (Summary);
   end Assert_Latest_Build_Result_Summary_Final_Not_Output_Log;

   function Assert_Latest_Build_Result_Summary_Final_Not_Diagnostics_Owner
     (Summary : Latest_Build_Result_Summary) return Boolean is
   begin
      return Assert_Latest_Build_Result_Summary_Not_Diagnostics_Owner (Summary);
   end Assert_Latest_Build_Result_Summary_Final_Not_Diagnostics_Owner;

   function Assert_Latest_Build_Result_Summary_Final_Render_Boundary
     (Summary : Latest_Build_Result_Summary) return Boolean is
   begin
      return Assert_Latest_Build_Result_Summary_Render_Cleanup (Summary)
        and then not Has_Runner_UI_Result_Field (Summary)
        and then not Has_Rerun_Request_Payload_Field (Summary)
        and then not Has_Diagnostics_Rows_Field (Summary);
   end Assert_Latest_Build_Result_Summary_Final_Render_Boundary;

   function Assert_Latest_Build_Result_Summary_Final_Persistence_Excluded
     (Summary : Latest_Build_Result_Summary) return Boolean is
   begin
      return Assert_Latest_Build_Result_Summary_Persistence_Excluded (Summary)
        and then not Has_Persistence_Field (Summary);
   end Assert_Latest_Build_Result_Summary_Final_Persistence_Excluded;

   function Assert_Public_Build_Result_Surface_Final_Freeze_Coherent
     (Summary : Latest_Build_Result_Summary) return Boolean is
   begin
      return Assert_Public_Build_Result_Surface_Canonical_Coherent (Summary)
        and then Assert_Latest_Build_Result_Summary_Final_Ownership_Frozen (Summary)
        and then Assert_Latest_Build_Result_Summary_Final_Shape_Frozen (Summary)
        and then Assert_Latest_Build_Result_Summary_Final_Mapping_Frozen (Summary)
        and then Assert_Latest_Build_Result_Summary_Final_No_History (Summary)
        and then Assert_Latest_Build_Result_Summary_Final_Not_Rerun_State (Summary)
        and then Assert_Latest_Build_Result_Summary_Final_Not_Process_Control (Summary)
        and then Assert_Latest_Build_Result_Summary_Final_Not_Output_Log (Summary)
        and then Assert_Latest_Build_Result_Summary_Final_Not_Diagnostics_Owner (Summary)
        and then Assert_Latest_Build_Result_Summary_Final_Render_Boundary (Summary)
        and then Assert_Latest_Build_Result_Summary_Final_Persistence_Excluded (Summary);
   end Assert_Public_Build_Result_Surface_Final_Freeze_Coherent;

   function Assert_Latest_Build_Result_Summary_Useful_For_Build_UI
     (Summary : Latest_Build_Result_Summary) return Boolean
   is
      Snapshot : constant Latest_Build_Result_Render_Snapshot :=
        Render_Snapshot (Summary);
   begin
      if not Summary.Has_Result then
         return not Snapshot.Latest_Build_Result_Visible
           and then Assert_Public_Build_Result_Surface_Final_Freeze_Coherent
             (Summary);
      end if;

      return Snapshot.Latest_Build_Result_Visible
        and then Length (Snapshot.Latest_Build_Result_Status_Label) > 0
        and then Length (Snapshot.Latest_Build_Result_Runner_Status_Label) > 0
        and then Length (Snapshot.Latest_Build_Result_Exit_Code_Label) > 0
        and then Length (Snapshot.Latest_Build_Result_Timeout_Label) > 0
        and then Length (Snapshot.Latest_Build_Result_Cancellation_Label) > 0
        and then Length (Snapshot.Latest_Build_Result_Truncation_Label) > 0
        and then Length (Snapshot.Latest_Build_Result_Partial_Output_Label) > 0
        and then Length (Snapshot.Latest_Build_Result_Diagnostics_Label) > 0
        and then Length (Snapshot.Latest_Build_Result_Primary_Message_Label) > 0
        and then Assert_Public_Build_Result_Surface_Final_Freeze_Coherent
          (Summary);
   end Assert_Latest_Build_Result_Summary_Useful_For_Build_UI;

end Editor.Build_Result_Summary;
