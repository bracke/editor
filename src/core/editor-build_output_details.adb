with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Build_Output_Details is

   function Empty_Output_Details return Latest_Build_Output_Details is
   begin
      return (others => <>);
   end Empty_Output_Details;


   function Empty_Build_Output_Stream return Build_Output_Stream_State is
   begin
      return (others => <>);
   end Empty_Build_Output_Stream;

   procedure Begin_Build_Output_Stream
     (Stream : in out Build_Output_Stream_State;
      Job_Id : Natural;
      Limit_Bytes : Natural := Max_Build_Output_Detail_Excerpt_Bytes)
   is
   begin
      Stream := Empty_Build_Output_Stream;
      Stream.Active := True;
      Stream.Associated_Job_Id := Job_Id;
      Stream.Limit_Bytes := Limit_Bytes;
   end Begin_Build_Output_Stream;

   procedure Append_Build_Output_Stream_Chunk
     (Stream : in out Build_Output_Stream_State;
      Output_Stream : Build_Output_Stream_Selection;
      Text : String)
   is
      Remaining : Natural := 0;
      To_Copy : Natural := 0;
   begin
      if not Stream.Active or else Text'Length = 0 then
         return;
      end if;

      Stream.Chunk_Count := Stream.Chunk_Count + 1;
      Stream.Byte_Count := Stream.Byte_Count + Text'Length;

      if Output_Stream = Build_Output_Stream_Stderr then
         if Length (Stream.Stderr_Text) < Stream.Limit_Bytes then
            Remaining := Stream.Limit_Bytes - Length (Stream.Stderr_Text);
            To_Copy := Natural'Min (Remaining, Text'Length);
            if To_Copy > 0 then
               Append (Stream.Stderr_Text, Text (Text'First .. Text'First + To_Copy - 1));
            end if;
         end if;
         if To_Copy < Text'Length then
            Stream.Stderr_Truncated := True;
         end if;
      else
         --  Stdout and merged fallback chunks share the stdout display buffer;
         --  merged provenance remains available on completed output details.
         if Length (Stream.Stdout_Text) < Stream.Limit_Bytes then
            Remaining := Stream.Limit_Bytes - Length (Stream.Stdout_Text);
            To_Copy := Natural'Min (Remaining, Text'Length);
            if To_Copy > 0 then
               Append (Stream.Stdout_Text, Text (Text'First .. Text'First + To_Copy - 1));
            end if;
         end if;
         if To_Copy < Text'Length then
            Stream.Stdout_Truncated := True;
         end if;
      end if;
   end Append_Build_Output_Stream_Chunk;

   function Build_Output_Details_From_Stream
     (Stream : Build_Output_Stream_State;
      Runner_Status : Build_Output_Runner_Status := Build_Output_Runner_Succeeded;
      Output_Partial : Boolean := True;
      Exit_Code : Integer := 0;
      Has_Exit_Code : Boolean := False)
      return Latest_Build_Output_Details
   is
   begin
      return Build_Output_Details_From_Captured_Output
        (Runner_Status => Runner_Status,
         Stdout_Text => Stream.Stdout_Text,
         Stderr_Text => Stream.Stderr_Text,
         Stdout_Truncated => Stream.Stdout_Truncated,
         Stderr_Truncated => Stream.Stderr_Truncated,
         Output_Partial => Output_Partial or else Stream.Active,
         Exit_Code => Exit_Code,
         Has_Exit_Code => Has_Exit_Code);
   end Build_Output_Details_From_Stream;

   procedure Finish_Build_Output_Stream
     (Stream : in out Build_Output_Stream_State)
   is
   begin
      Stream.Active := False;
   end Finish_Build_Output_Stream;

   function Assert_Build_Output_Stream_Bounded
     (Stream : Build_Output_Stream_State) return Boolean
   is
   begin
      return Length (Stream.Stdout_Text) <= Stream.Limit_Bytes
        and then Length (Stream.Stderr_Text) <= Stream.Limit_Bytes;
   end Assert_Build_Output_Stream_Bounded;

   function Build_Status_Label
     (Status : Build_Output_Runner_Status) return String
   is
   begin
      case Status is
         when Build_Output_Runner_Succeeded => return "succeeded";
         when Build_Output_Runner_Failed => return "failed";
         when Build_Output_Runner_Not_Available => return "not available";
         when Build_Output_Runner_Rejected => return "rejected";
         when Build_Output_Runner_Execution_Error => return "execution error";
         when Build_Output_Runner_Timed_Out => return "timed out";
         when Build_Output_Runner_Cancelled => return "cancelled";
         when Build_Output_Runner_Cancellation_Unsupported => return "cancellation unsupported";
         when Build_Output_Runner_Output_Truncated => return "output truncated";
      end case;
   end Build_Status_Label;

   function Result_Identity
     (Runner_Status    : Build_Output_Runner_Status;
      Stdout_Text      : Ada.Strings.Unbounded.Unbounded_String;
      Stderr_Text      : Ada.Strings.Unbounded.Unbounded_String;
      Stdout_Truncated : Boolean;
      Stderr_Truncated : Boolean;
      Output_Partial   : Boolean;
      Exit_Code        : Integer;
      Has_Exit_Code    : Boolean;
      Output_Stream    : Build_Output_Stream_Selection) return String
   is
   begin
      return Build_Output_Runner_Status'Image (Runner_Status)
        & ":exit=" & Integer'Image (Exit_Code)
        & ":has-exit=" & Boolean'Image (Has_Exit_Code)
        & ":stdout=" & Natural'Image (Length (Stdout_Text))
        & ":stderr=" & Natural'Image (Length (Stderr_Text))
        & ":stdout-truncated=" & Boolean'Image (Stdout_Truncated)
        & ":stderr-truncated=" & Boolean'Image (Stderr_Truncated)
        & ":partial=" & Boolean'Image (Output_Partial)
        & ":stream=" & Build_Output_Stream_Selection'Image (Output_Stream);
   end Result_Identity;

   function Bound_Build_Output_Excerpt
     (Text  : Ada.Strings.Unbounded.Unbounded_String;
      Limit : Natural := Max_Build_Output_Detail_Excerpt_Bytes)
      return Ada.Strings.Unbounded.Unbounded_String
   is
      S : constant String := To_String (Text);
   begin
      if Limit = 0 or else S'Length = 0 then
         return Null_Unbounded_String;
      elsif S'Length <= Limit then
         return Text;
      else
         return To_Unbounded_String (S (S'First .. S'First + Limit - 1));
      end if;
   end Bound_Build_Output_Excerpt;

   function Details_Kind_For
     (Runner_Status : Build_Output_Runner_Status;
      Stdout_Truncated : Boolean;
      Stderr_Truncated : Boolean;
      Output_Partial : Boolean;
      Has_Output   : Boolean;
      Display_Truncated : Boolean) return Build_Output_Details_Kind
   is
      Partial : constant Boolean :=
        Output_Partial
        or else Runner_Status in
          Build_Output_Runner_Timed_Out |
          Build_Output_Runner_Cancelled;
   begin
      if not Has_Output then
         return Build_Output_Details_Unavailable;
      elsif Partial then
         return Build_Output_Details_Partial;
      elsif Stdout_Truncated
        or else Stderr_Truncated
        or else Display_Truncated
        or else Runner_Status = Build_Output_Runner_Output_Truncated
      then
         return Build_Output_Details_Truncated;
      else
         return Build_Output_Details_Available;
      end if;
   end Details_Kind_For;

   function Build_Output_Details_From_Captured_Output
     (Runner_Status    : Build_Output_Runner_Status;
      Stdout_Text      : Ada.Strings.Unbounded.Unbounded_String;
      Stderr_Text      : Ada.Strings.Unbounded.Unbounded_String;
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Output_Partial   : Boolean := False;
      Exit_Code        : Integer := 0;
      Has_Exit_Code    : Boolean := False;
      Output_Stream    : Build_Output_Stream_Selection :=
        Build_Output_Stream_Stderr)
      return Latest_Build_Output_Details
   is
      Stdout_Length : constant Natural := Length (Stdout_Text);
      Stderr_Length : constant Natural := Length (Stderr_Text);
      Stdout_Display_Truncated : constant Boolean :=
        Stdout_Length > Max_Build_Output_Detail_Excerpt_Bytes;
      Stderr_Display_Truncated : constant Boolean :=
        Stderr_Length > Max_Build_Output_Detail_Excerpt_Bytes;
      Has_Output : constant Boolean := Stdout_Length > 0 or else Stderr_Length > 0;
      Partial : constant Boolean :=
        Output_Partial
        or else Runner_Status in
          Build_Output_Runner_Timed_Out |
          Build_Output_Runner_Cancelled;
   begin
      return Canonicalize_Latest_Build_Output_Details
        ((Has_Output_Details => True,
          Kind => Details_Kind_For
            (Runner_Status, Stdout_Truncated, Stderr_Truncated, Output_Partial,
             Has_Output,
             Stdout_Display_Truncated or else Stderr_Display_Truncated),
          Associated_Result_Identity => To_Unbounded_String
            (Result_Identity
               (Runner_Status, Stdout_Text, Stderr_Text, Stdout_Truncated,
                Stderr_Truncated, Output_Partial, Exit_Code, Has_Exit_Code,
                Output_Stream)),
          Stdout_Available => Stdout_Length > 0,
          Stderr_Available => Stderr_Length > 0,
          Stdout_Excerpt => Bound_Build_Output_Excerpt (Stdout_Text),
          Stderr_Excerpt => Bound_Build_Output_Excerpt (Stderr_Text),
          Stdout_Truncated => Stdout_Truncated,
          Stderr_Truncated => Stderr_Truncated,
          Stdout_Display_Truncated => Stdout_Display_Truncated,
          Stderr_Display_Truncated => Stderr_Display_Truncated,
          Output_Partial => Partial,
          Timed_Out => Runner_Status = Build_Output_Runner_Timed_Out,
          Cancelled => Runner_Status = Build_Output_Runner_Cancelled,
          Runner_Status => To_Unbounded_String (Build_Status_Label (Runner_Status)),
          Output_Limit_Label => To_Unbounded_String
            ("bounded display excerpt <=" &
             Natural'Image (Max_Build_Output_Detail_Excerpt_Bytes) & " bytes"),
          Build_Output_Details_Visible => False,
          Build_Output_Details_Focused => False,
          Selected_Output_Stream =>
            (if Output_Stream = Build_Output_Stream_Merged then
                Build_Output_Stream_Merged
             elsif Stderr_Length > 0 then Build_Output_Stream_Stderr
             else Build_Output_Stream_Stdout)));
   end Build_Output_Details_From_Captured_Output;

   function Build_Unavailable_Output_Details
     (Reason : String := "") return Latest_Build_Output_Details
   is
      Label : constant String :=
        (if Reason'Length > 0 then Reason else "output unavailable");
   begin
      return
        (Has_Output_Details => True,
         Kind => Build_Output_Details_Unavailable,
         Associated_Result_Identity => To_Unbounded_String (Label),
         Runner_Status => To_Unbounded_String ("not available"),
         Output_Limit_Label => To_Unbounded_String
           ("bounded display excerpt <=" &
            Natural'Image (Max_Build_Output_Detail_Excerpt_Bytes) & " bytes"),
         others => <>);
   end Build_Unavailable_Output_Details;

   function Canonicalize_Latest_Build_Output_Details
     (Details : Latest_Build_Output_Details)
      return Latest_Build_Output_Details
   is
      Result : Latest_Build_Output_Details := Details;
   begin
      if not Result.Has_Output_Details then
         return Empty_Output_Details;
      end if;

      if Result.Kind = Build_Output_Details_None then
         Result.Kind := Build_Output_Details_Unavailable;
      end if;

      Result.Stdout_Excerpt := Bound_Build_Output_Excerpt (Result.Stdout_Excerpt);
      Result.Stderr_Excerpt := Bound_Build_Output_Excerpt (Result.Stderr_Excerpt);
      Result.Stdout_Available := Length (Result.Stdout_Excerpt) > 0;
      Result.Stderr_Available := Length (Result.Stderr_Excerpt) > 0;

      if not Result.Stdout_Available then
         Result.Stdout_Truncated := False;
         Result.Stdout_Display_Truncated := False;
      end if;
      if not Result.Stderr_Available then
         Result.Stderr_Truncated := False;
         Result.Stderr_Display_Truncated := False;
      end if;

      Result.Output_Partial := Result.Output_Partial
        or else Result.Timed_Out
        or else Result.Cancelled;

      if not Result.Stdout_Available and then not Result.Stderr_Available then
         Result.Kind := Build_Output_Details_Unavailable;
      elsif Result.Output_Partial then
         Result.Kind := Build_Output_Details_Partial;
      elsif Result.Stdout_Truncated or else Result.Stderr_Truncated
        or else Result.Stdout_Display_Truncated
        or else Result.Stderr_Display_Truncated
      then
         Result.Kind := Build_Output_Details_Truncated;
      else
         Result.Kind := Build_Output_Details_Available;
      end if;

      if Length (Result.Output_Limit_Label) = 0 then
         Result.Output_Limit_Label := To_Unbounded_String
           ("bounded display excerpt <=" &
            Natural'Image (Max_Build_Output_Detail_Excerpt_Bytes) & " bytes");
      end if;

      return Result;
   end Canonicalize_Latest_Build_Output_Details;

   function Clear_Stale_Output_Details_Fields
     (Details : Latest_Build_Output_Details)
      return Latest_Build_Output_Details
   is
      Result : Latest_Build_Output_Details :=
        Canonicalize_Latest_Build_Output_Details (Details);
   begin
      if not Result.Stdout_Available then
         Result.Stdout_Excerpt := Null_Unbounded_String;
         Result.Stdout_Truncated := False;
         Result.Stdout_Display_Truncated := False;
      end if;

      if not Result.Stderr_Available then
         Result.Stderr_Excerpt := Null_Unbounded_String;
         Result.Stderr_Truncated := False;
         Result.Stderr_Display_Truncated := False;
      end if;

      if not Result.Timed_Out and then not Result.Cancelled
        and then Result.Kind /= Build_Output_Details_Partial
      then
         Result.Output_Partial := False;
      end if;

      return Canonicalize_Latest_Build_Output_Details (Result);
   end Clear_Stale_Output_Details_Fields;

   function Clear_Stale_Build_Output_Details_Fields
     (Details : Latest_Build_Output_Details)
      return Latest_Build_Output_Details
   is
   begin
      return Clear_Stale_Output_Details_Fields (Details);
   end Clear_Stale_Build_Output_Details_Fields;

   function Build_Output_Details_No_Output_State
     (Runner_Status : Build_Output_Runner_Status;
      Exit_Code     : Integer := 0;
      Has_Exit_Code : Boolean := False)
      return Latest_Build_Output_Details
   is
   begin
      return Build_Output_Details_From_Captured_Output
        (Runner_Status => Runner_Status,
         Stdout_Text => Null_Unbounded_String,
         Stderr_Text => Null_Unbounded_String,
         Exit_Code => Exit_Code,
         Has_Exit_Code => Has_Exit_Code);
   end Build_Output_Details_No_Output_State;

   function Build_Output_Details_Partial_Output_State
     (Runner_Status    : Build_Output_Runner_Status;
      Stdout_Text      : Ada.Strings.Unbounded.Unbounded_String;
      Stderr_Text      : Ada.Strings.Unbounded.Unbounded_String;
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False)
      return Latest_Build_Output_Details
   is
   begin
      return Build_Output_Details_From_Captured_Output
        (Runner_Status => Runner_Status,
         Stdout_Text => Stdout_Text,
         Stderr_Text => Stderr_Text,
         Stdout_Truncated => Stdout_Truncated,
         Stderr_Truncated => Stderr_Truncated,
         Output_Partial => True);
   end Build_Output_Details_Partial_Output_State;

   function Replace_Latest_Build_Output_Details
     (Current : Latest_Build_Output_Details;
      Next    : Latest_Build_Output_Details)
      return Latest_Build_Output_Details
   is
      pragma Unreferenced (Current);
   begin
      return Clear_Stale_Output_Details_Fields (Next);
   end Replace_Latest_Build_Output_Details;

   function Replace_Latest_Build_Output_Details_Reliably
     (Current : Latest_Build_Output_Details;
      Next    : Latest_Build_Output_Details)
      return Latest_Build_Output_Details
   is
   begin
      return Replace_Latest_Build_Output_Details (Current, Next);
   end Replace_Latest_Build_Output_Details_Reliably;

   procedure Show_Output_Details
     (Details : in out Latest_Build_Output_Details)
   is
   begin
      Details.Build_Output_Details_Visible := True;
   end Show_Output_Details;

   procedure Focus_Output_Details
     (Details : in out Latest_Build_Output_Details)
   is
   begin
      Details.Build_Output_Details_Visible := True;
      Details.Build_Output_Details_Focused := True;
   end Focus_Output_Details;

   procedure Hide_Output_Details
     (Details : in out Latest_Build_Output_Details)
   is
   begin
      Details.Build_Output_Details_Visible := False;
      Details.Build_Output_Details_Focused := False;
   end Hide_Output_Details;

   procedure Select_Output_Stream
     (Details : in out Latest_Build_Output_Details;
      Stream  : Build_Output_Stream_Selection)
   is
   begin
      Details.Selected_Output_Stream := Stream;
   end Select_Output_Stream;

   function Status_Label (Details : Latest_Build_Output_Details) return String is
   begin
      if not Details.Has_Output_Details then
         return "No build output captured.";
      end if;
      case Details.Kind is
         when Build_Output_Details_None => return "No build output captured.";
         when Build_Output_Details_Available => return "Build output captured.";
         when Build_Output_Details_Unavailable => return "No build output captured.";
         when Build_Output_Details_Truncated => return "Build output captured and truncated.";
         when Build_Output_Details_Partial => return "Build output captured partially.";
      end case;
   end Status_Label;

   function Stdout_Truncation_Label
     (Details : Latest_Build_Output_Details) return String
   is
   begin
      if Details.Stdout_Truncated and then Details.Stdout_Display_Truncated then
         return "stdout truncated; stdout display excerpt truncated";
      elsif Details.Stdout_Truncated then
         return "stdout truncated";
      elsif Details.Stdout_Display_Truncated then
         return "stdout display excerpt truncated";
      elsif Details.Stdout_Available then
         return "stdout captured within display bound";
      else
         return "No stdout captured.";
      end if;
   end Stdout_Truncation_Label;

   function Stderr_Truncation_Label
     (Details : Latest_Build_Output_Details) return String
   is
   begin
      if Details.Stderr_Truncated and then Details.Stderr_Display_Truncated then
         return "stderr truncated; stderr display excerpt truncated";
      elsif Details.Stderr_Truncated then
         return "stderr truncated";
      elsif Details.Stderr_Display_Truncated then
         return "stderr display excerpt truncated";
      elsif Details.Stderr_Available then
         return "stderr captured within display bound";
      else
         return "No stderr captured.";
      end if;
   end Stderr_Truncation_Label;

   function Partial_Output_Label
     (Details : Latest_Build_Output_Details) return String
   is
   begin
      if Details.Timed_Out then
         return "build timed out; output may be incomplete";
      elsif Details.Cancelled then
         return "build cancelled; output may be incomplete";
      elsif Details.Output_Partial then
         return "Partial output captured";
      else
         return "output captured completely within bounds";
      end if;
   end Partial_Output_Label;

   function No_Output_Label
     (Details : Latest_Build_Output_Details) return String
   is
   begin
      if Details.Has_Output_Details
        and then not Details.Stdout_Available
        and then not Details.Stderr_Available
      then
         return "No build output captured.";
      end if;
      return "build output captured";
   end No_Output_Label;

   function Render_Snapshot
     (Details : Latest_Build_Output_Details)
      return Latest_Build_Output_Details_Render_Snapshot
   is
      Canonical : constant Latest_Build_Output_Details :=
        Canonicalize_Latest_Build_Output_Details (Details);
   begin
      if not Canonical.Has_Output_Details then
         return (others => <>);
      end if;

      return
        (Output_Details_Visible => Canonical.Build_Output_Details_Visible,
         Output_Details_Focused => Canonical.Build_Output_Details_Focused,
         Output_Details_Available =>
           Canonical.Stdout_Available or else Canonical.Stderr_Available,
         No_Output_Label => To_Unbounded_String
           (No_Output_Label (Canonical)),
         Output_Details_Status_Label => To_Unbounded_String
           (Status_Label (Canonical)),
         Output_Details_Runner_Status_Label => Canonical.Runner_Status,
         Output_Details_Limit_Label => Canonical.Output_Limit_Label,
         Stdout_Available => Canonical.Stdout_Available,
         Stderr_Available => Canonical.Stderr_Available,
         Stdout_No_Output_Label =>
           (if Canonical.Stdout_Available then Null_Unbounded_String
            else To_Unbounded_String ("No stdout captured.")),
         Stderr_No_Output_Label =>
           (if Canonical.Stderr_Available then Null_Unbounded_String
            else To_Unbounded_String ("No stderr captured.")),
         Stdout_Excerpt => Canonical.Stdout_Excerpt,
         Stderr_Excerpt => Canonical.Stderr_Excerpt,
         Stdout_Truncation_Label => To_Unbounded_String
           (Stdout_Truncation_Label (Canonical)),
         Stderr_Truncation_Label => To_Unbounded_String
           (Stderr_Truncation_Label (Canonical)),
         Partial_Output_Label => To_Unbounded_String
           (Partial_Output_Label (Canonical)),
         Selected_Output_Stream => Canonical.Selected_Output_Stream);
   end Render_Snapshot;

   function Has_Process_Handle_Field
     (Details : Latest_Build_Output_Details) return Boolean is
      pragma Unreferenced (Details);
   begin
      return False;
   end Has_Process_Handle_Field;

   function Has_Cancellation_Token_Field
     (Details : Latest_Build_Output_Details) return Boolean is
      pragma Unreferenced (Details);
   begin
      return False;
   end Has_Cancellation_Token_Field;

   function Has_Rerun_Request_Payload_Field
     (Details : Latest_Build_Output_Details) return Boolean is
      pragma Unreferenced (Details);
   begin
      return False;
   end Has_Rerun_Request_Payload_Field;

   function Has_Public_Build_Request_Field
     (Details : Latest_Build_Output_Details) return Boolean is
      pragma Unreferenced (Details);
   begin
      return False;
   end Has_Public_Build_Request_Field;

   function Has_Consent_Field
     (Details : Latest_Build_Output_Details) return Boolean is
      pragma Unreferenced (Details);
   begin
      return False;
   end Has_Consent_Field;

   function Has_Working_Context_Token_Field
     (Details : Latest_Build_Output_Details) return Boolean is
      pragma Unreferenced (Details);
   begin
      return False;
   end Has_Working_Context_Token_Field;

   function Has_Diagnostics_Rows_Field
     (Details : Latest_Build_Output_Details) return Boolean is
      pragma Unreferenced (Details);
   begin
      return False;
   end Has_Diagnostics_Rows_Field;

   function Has_Build_History_Field
     (Details : Latest_Build_Output_Details) return Boolean is
      pragma Unreferenced (Details);
   begin
      return False;
   end Has_Build_History_Field;

   function Has_Unbounded_Output_Field
     (Details : Latest_Build_Output_Details) return Boolean is
   begin
      return Length (Details.Stdout_Excerpt) > Max_Build_Output_Detail_Excerpt_Bytes
        or else Length (Details.Stderr_Excerpt) > Max_Build_Output_Detail_Excerpt_Bytes;
   end Has_Unbounded_Output_Field;

   function Has_Output_File_Path_Field
     (Details : Latest_Build_Output_Details) return Boolean is
      pragma Unreferenced (Details);
   begin
      return False;
   end Has_Output_File_Path_Field;

   function Has_Persistence_Field
     (Details : Latest_Build_Output_Details) return Boolean is
      pragma Unreferenced (Details);
   begin
      return False;
   end Has_Persistence_Field;

   function Assert_Build_Output_Details_Bounded
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return not Has_Unbounded_Output_Field (Details)
        and then Length (Details.Stdout_Excerpt) <= Max_Build_Output_Detail_Excerpt_Bytes
        and then Length (Details.Stderr_Excerpt) <= Max_Build_Output_Detail_Excerpt_Bytes;
   end Assert_Build_Output_Details_Bounded;

   function Assert_Build_Output_Details_Transient
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Build_Output_Details_Bounded (Details)
        and then not Has_Persistence_Field (Details)
        and then not Has_Build_History_Field (Details)
        and then not Has_Output_File_Path_Field (Details);
   end Assert_Build_Output_Details_Transient;

   function Assert_Build_Output_Details_Updated_By_Executor
     (Details : Latest_Build_Output_Details) return Boolean is
      pragma Unreferenced (Details);
   begin
      return True;
   end Assert_Build_Output_Details_Updated_By_Executor;

   function Assert_Build_Output_Details_Not_Diagnostics_Owner
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return not Has_Diagnostics_Rows_Field (Details);
   end Assert_Build_Output_Details_Not_Diagnostics_Owner;

   function Assert_Build_Output_Details_Not_Rerun_State
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return not Has_Rerun_Request_Payload_Field (Details)
        and then not Has_Public_Build_Request_Field (Details)
        and then not Has_Consent_Field (Details)
        and then not Has_Working_Context_Token_Field (Details);
   end Assert_Build_Output_Details_Not_Rerun_State;

   function Assert_Build_Output_Details_Not_Process_Control
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return not Has_Process_Handle_Field (Details)
        and then not Has_Cancellation_Token_Field (Details);
   end Assert_Build_Output_Details_Not_Process_Control;

   function Assert_Build_Output_Details_Persistence_Excluded
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return not Has_Persistence_Field (Details)
        and then not Has_Output_File_Path_Field (Details)
        and then not Has_Build_History_Field (Details);
   end Assert_Build_Output_Details_Persistence_Excluded;

   function Assert_Build_Output_Details_Replace_Only
     (Before : Latest_Build_Output_Details;
      After  : Latest_Build_Output_Details) return Boolean
   is
      Replaced : constant Latest_Build_Output_Details :=
        Replace_Latest_Build_Output_Details (Before, After);
      Canonical_After : constant Latest_Build_Output_Details :=
        Clear_Stale_Output_Details_Fields (After);
   begin
      return Replaced.Has_Output_Details = Canonical_After.Has_Output_Details
        and then Replaced.Kind = Canonical_After.Kind
        and then To_String (Replaced.Associated_Result_Identity) =
          To_String (Canonical_After.Associated_Result_Identity)
        and then Replaced.Stdout_Available = Canonical_After.Stdout_Available
        and then Replaced.Stderr_Available = Canonical_After.Stderr_Available
        and then To_String (Replaced.Stdout_Excerpt) =
          To_String (Canonical_After.Stdout_Excerpt)
        and then To_String (Replaced.Stderr_Excerpt) =
          To_String (Canonical_After.Stderr_Excerpt)
        and then Replaced.Stdout_Truncated = Canonical_After.Stdout_Truncated
        and then Replaced.Stderr_Truncated = Canonical_After.Stderr_Truncated
        and then Replaced.Stdout_Display_Truncated =
          Canonical_After.Stdout_Display_Truncated
        and then Replaced.Stderr_Display_Truncated =
          Canonical_After.Stderr_Display_Truncated
        and then Replaced.Output_Partial = Canonical_After.Output_Partial
        and then Replaced.Timed_Out = Canonical_After.Timed_Out
        and then Replaced.Cancelled = Canonical_After.Cancelled;
   end Assert_Build_Output_Details_Replace_Only;

   function Assert_Output_Details_Replaced_Not_Appended
     (Before : Latest_Build_Output_Details;
      After  : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Build_Output_Details_Replace_Only (Before, After);
   end Assert_Output_Details_Replaced_Not_Appended;

   function Assert_Output_Details_Stale_Fields_Cleared
     (Before : Latest_Build_Output_Details;
      After  : Latest_Build_Output_Details) return Boolean
   is
      Replaced : constant Latest_Build_Output_Details :=
        Replace_Latest_Build_Output_Details (Before, After);
   begin
      return (Replaced.Stdout_Available or else Length (Replaced.Stdout_Excerpt) = 0)
        and then (Replaced.Stderr_Available or else Length (Replaced.Stderr_Excerpt) = 0)
        and then (Replaced.Stdout_Available or else not Replaced.Stdout_Truncated)
        and then (Replaced.Stderr_Available or else not Replaced.Stderr_Truncated)
        and then (Replaced.Stdout_Available or else not Replaced.Stdout_Display_Truncated)
        and then (Replaced.Stderr_Available or else not Replaced.Stderr_Display_Truncated)
        and then (Replaced.Timed_Out or else Replaced.Cancelled
                  or else Replaced.Kind = Build_Output_Details_Partial
                  or else not Replaced.Output_Partial);
   end Assert_Output_Details_Stale_Fields_Cleared;

   function Assert_Output_Details_Not_History
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return not Has_Build_History_Field (Details);
   end Assert_Output_Details_Not_History;

   function Assert_Output_Details_Not_Rerun_State
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Build_Output_Details_Not_Rerun_State (Details);
   end Assert_Output_Details_Not_Rerun_State;

   function Assert_Output_Details_Not_Process_Control
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Build_Output_Details_Not_Process_Control (Details);
   end Assert_Output_Details_Not_Process_Control;

   function Assert_Output_Details_Not_Diagnostics_Owner
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Build_Output_Details_Not_Diagnostics_Owner (Details);
   end Assert_Output_Details_Not_Diagnostics_Owner;

   function Assert_Output_Details_Persistence_Excluded
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Build_Output_Details_Persistence_Excluded (Details);
   end Assert_Output_Details_Persistence_Excluded;

   function Assert_Public_Build_Output_Details_Foundation_Coherent
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Build_Output_Details_Updated_By_Executor (Details)
        and then Assert_Build_Output_Details_Bounded (Details)
        and then Assert_Build_Output_Details_Transient (Details)
        and then Assert_Build_Output_Details_Not_Process_Control (Details)
        and then Assert_Build_Output_Details_Not_Rerun_State (Details)
        and then Assert_Build_Output_Details_Not_Diagnostics_Owner (Details)
        and then Assert_Build_Output_Details_Persistence_Excluded (Details);
   end Assert_Public_Build_Output_Details_Foundation_Coherent;

   function Assert_Public_Build_Output_Details_Reliability_Coherent
     (Details : Latest_Build_Output_Details) return Boolean
   is
      Canonical : constant Latest_Build_Output_Details :=
        Clear_Stale_Output_Details_Fields (Details);
   begin
      return Assert_Public_Build_Output_Details_Foundation_Coherent (Canonical)
        and then (Canonical.Stdout_Available or else Length (Canonical.Stdout_Excerpt) = 0)
        and then (Canonical.Stderr_Available or else Length (Canonical.Stderr_Excerpt) = 0)
        and then (Canonical.Stdout_Available or else not Canonical.Stdout_Truncated)
        and then (Canonical.Stderr_Available or else not Canonical.Stderr_Truncated)
        and then (Canonical.Stdout_Available or else not Canonical.Stdout_Display_Truncated)
        and then (Canonical.Stderr_Available or else not Canonical.Stderr_Display_Truncated)
        and then not Has_Unbounded_Output_Field (Canonical)
        and then not Has_Process_Handle_Field (Canonical)
        and then not Has_Cancellation_Token_Field (Canonical)
        and then not Has_Rerun_Request_Payload_Field (Canonical)
        and then not Has_Public_Build_Request_Field (Canonical)
        and then not Has_Consent_Field (Canonical)
        and then not Has_Working_Context_Token_Field (Canonical)
        and then not Has_Diagnostics_Rows_Field (Canonical)
        and then not Has_Build_History_Field (Canonical)
        and then not Has_Persistence_Field (Canonical);
   end Assert_Public_Build_Output_Details_Reliability_Coherent;


   function Assert_Latest_Build_Output_Details_Owned_By_Executor
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Build_Output_Details_Updated_By_Executor (Details);
   end Assert_Latest_Build_Output_Details_Owned_By_Executor;

   function Assert_Latest_Build_Output_Details_Shape_Canonical
     (Details : Latest_Build_Output_Details) return Boolean
   is
      Canonical : constant Latest_Build_Output_Details :=
        Canonicalize_Latest_Build_Output_Details (Details);
   begin
      return Assert_Build_Output_Details_Bounded (Canonical)
        and then not Has_Process_Handle_Field (Canonical)
        and then not Has_Cancellation_Token_Field (Canonical)
        and then not Has_Rerun_Request_Payload_Field (Canonical)
        and then not Has_Public_Build_Request_Field (Canonical)
        and then not Has_Consent_Field (Canonical)
        and then not Has_Working_Context_Token_Field (Canonical)
        and then not Has_Diagnostics_Rows_Field (Canonical)
        and then not Has_Build_History_Field (Canonical)
        and then not Has_Output_File_Path_Field (Canonical)
        and then not Has_Persistence_Field (Canonical)
        and then not Has_Unbounded_Output_Field (Canonical)
        and then (Canonical.Stdout_Available or else Length (Canonical.Stdout_Excerpt) = 0)
        and then (Canonical.Stderr_Available or else Length (Canonical.Stderr_Excerpt) = 0)
        and then (Canonical.Stdout_Available or else not Canonical.Stdout_Truncated)
        and then (Canonical.Stderr_Available or else not Canonical.Stderr_Truncated)
        and then (Canonical.Stdout_Available or else not Canonical.Stdout_Display_Truncated)
        and then (Canonical.Stderr_Available or else not Canonical.Stderr_Display_Truncated);
   end Assert_Latest_Build_Output_Details_Shape_Canonical;

   function Assert_Latest_Build_Output_Details_Replace_Only
     (Before : Latest_Build_Output_Details;
      After  : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Build_Output_Details_Replace_Only (Before, After)
        and then Assert_Output_Details_Stale_Fields_Cleared (Before, After)
        and then Assert_Output_Details_Replaced_Not_Appended (Before, After);
   end Assert_Latest_Build_Output_Details_Replace_Only;

   function Assert_Latest_Build_Output_Details_No_Output_Canonical
     (Details : Latest_Build_Output_Details) return Boolean
   is
      Canonical : constant Latest_Build_Output_Details :=
        Canonicalize_Latest_Build_Output_Details (Details);
   begin
      if not Canonical.Has_Output_Details then
         return True;
      elsif Canonical.Stdout_Available or else Canonical.Stderr_Available then
         return True;
      end if;

      return Canonical.Has_Output_Details
        and then Canonical.Kind = Build_Output_Details_Unavailable
        and then Length (Canonical.Stdout_Excerpt) = 0
        and then Length (Canonical.Stderr_Excerpt) = 0
        and then not Canonical.Stdout_Truncated
        and then not Canonical.Stderr_Truncated
        and then not Canonical.Stdout_Display_Truncated
        and then not Canonical.Stderr_Display_Truncated
        and then not Has_Diagnostics_Rows_Field (Canonical)
        and then not Has_Build_History_Field (Canonical)
        and then not Has_Unbounded_Output_Field (Canonical);
   end Assert_Latest_Build_Output_Details_No_Output_Canonical;

   function Assert_Latest_Build_Output_Details_Not_Rerun_State
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Build_Output_Details_Not_Rerun_State (Details);
   end Assert_Latest_Build_Output_Details_Not_Rerun_State;

   function Assert_Latest_Build_Output_Details_Not_Process_Control
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Output_Details_Not_Process_Control (Details);
   end Assert_Latest_Build_Output_Details_Not_Process_Control;

   function Assert_Latest_Build_Output_Details_Not_Diagnostics_Owner
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Build_Output_Details_Not_Diagnostics_Owner (Details);
   end Assert_Latest_Build_Output_Details_Not_Diagnostics_Owner;

   function Assert_Latest_Build_Output_Details_Not_Output_Log
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return not Has_Unbounded_Output_Field (Details)
        and then not Has_Output_File_Path_Field (Details)
        and then not Has_Build_History_Field (Details)
        and then Assert_Build_Output_Details_Bounded (Details);
   end Assert_Latest_Build_Output_Details_Not_Output_Log;

   function Assert_Latest_Build_Output_Details_Render_Cleanup
     (Details : Latest_Build_Output_Details) return Boolean
   is
      Before : constant Latest_Build_Output_Details :=
        Canonicalize_Latest_Build_Output_Details (Details);
      Snapshot : constant Latest_Build_Output_Details_Render_Snapshot :=
        Render_Snapshot (Details);
      After : constant Latest_Build_Output_Details :=
        Canonicalize_Latest_Build_Output_Details (Details);
   begin
      return To_String (Before.Associated_Result_Identity) =
          To_String (After.Associated_Result_Identity)
        and then To_String (Before.Stdout_Excerpt) = To_String (After.Stdout_Excerpt)
        and then To_String (Before.Stderr_Excerpt) = To_String (After.Stderr_Excerpt)
        and then Before.Stdout_Available = After.Stdout_Available
        and then Before.Stderr_Available = After.Stderr_Available
        and then Snapshot.Stdout_Available = Before.Stdout_Available
        and then Snapshot.Stderr_Available = Before.Stderr_Available
        and then To_String (Snapshot.Stdout_Excerpt) = To_String (Before.Stdout_Excerpt)
        and then To_String (Snapshot.Stderr_Excerpt) = To_String (Before.Stderr_Excerpt);
   end Assert_Latest_Build_Output_Details_Render_Cleanup;

   function Assert_Latest_Build_Output_Details_Persistence_Excluded
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Build_Output_Details_Persistence_Excluded (Details);
   end Assert_Latest_Build_Output_Details_Persistence_Excluded;

   function Assert_Public_Build_Output_Details_Canonical_Coherent
     (Details : Latest_Build_Output_Details) return Boolean
   is
      Canonical : constant Latest_Build_Output_Details :=
        Clear_Stale_Build_Output_Details_Fields (Details);
   begin
      return Assert_Public_Build_Output_Details_Reliability_Coherent (Canonical)
        and then Assert_Latest_Build_Output_Details_Owned_By_Executor (Canonical)
        and then Assert_Latest_Build_Output_Details_Shape_Canonical (Canonical)
        and then Assert_Latest_Build_Output_Details_No_Output_Canonical (Canonical)
        and then Assert_Latest_Build_Output_Details_Not_Rerun_State (Canonical)
        and then Assert_Latest_Build_Output_Details_Not_Diagnostics_Owner (Canonical)
        and then Assert_Latest_Build_Output_Details_Not_Output_Log (Canonical)
        and then Assert_Latest_Build_Output_Details_Render_Cleanup (Canonical)
        and then Assert_Latest_Build_Output_Details_Persistence_Excluded (Canonical);
   end Assert_Public_Build_Output_Details_Canonical_Coherent;


   function Assert_Latest_Build_Output_Details_Final_Ownership_Frozen
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Latest_Build_Output_Details_Owned_By_Executor (Details);
   end Assert_Latest_Build_Output_Details_Final_Ownership_Frozen;

   function Assert_Latest_Build_Output_Details_Final_Shape_Frozen
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Latest_Build_Output_Details_Shape_Canonical (Details);
   end Assert_Latest_Build_Output_Details_Final_Shape_Frozen;

   function Assert_Latest_Build_Output_Details_Final_Mapping_Frozen
     (Details : Latest_Build_Output_Details) return Boolean
   is
      Canonical : constant Latest_Build_Output_Details :=
        Canonicalize_Latest_Build_Output_Details (Details);
   begin
      if not Canonical.Has_Output_Details then
         return Canonical.Kind = Build_Output_Details_None
           and then Length (Canonical.Stdout_Excerpt) = 0
           and then Length (Canonical.Stderr_Excerpt) = 0;
      end if;

      return Assert_Latest_Build_Output_Details_Shape_Canonical (Canonical)
        and then Length (Canonical.Runner_Status) > 0
        and then Length (Canonical.Output_Limit_Label) > 0
        and then (Canonical.Stdout_Available = (Length (Canonical.Stdout_Excerpt) > 0))
        and then (Canonical.Stderr_Available = (Length (Canonical.Stderr_Excerpt) > 0))
        and then (if Canonical.Kind = Build_Output_Details_Partial
                  then Canonical.Output_Partial else True)
        and then (if Canonical.Timed_Out or else Canonical.Cancelled
                  then Canonical.Output_Partial else True);
   end Assert_Latest_Build_Output_Details_Final_Mapping_Frozen;

   function Assert_Latest_Build_Output_Details_Final_No_Output_Frozen
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Latest_Build_Output_Details_No_Output_Canonical (Details);
   end Assert_Latest_Build_Output_Details_Final_No_Output_Frozen;

   function Assert_Latest_Build_Output_Details_Final_Replace_Only_Frozen
     (Before : Latest_Build_Output_Details;
      After  : Latest_Build_Output_Details) return Boolean
   is
      Replaced : constant Latest_Build_Output_Details :=
        Replace_Latest_Build_Output_Details (Before, After);
      Canonical_After : constant Latest_Build_Output_Details :=
        Clear_Stale_Output_Details_Fields (After);
   begin
      return Assert_Latest_Build_Output_Details_Replace_Only (Before, After)
        and then To_String (Replaced.Associated_Result_Identity) =
          To_String (Canonical_After.Associated_Result_Identity)
        and then To_String (Replaced.Stdout_Excerpt) =
          To_String (Canonical_After.Stdout_Excerpt)
        and then To_String (Replaced.Stderr_Excerpt) =
          To_String (Canonical_After.Stderr_Excerpt)
        and then Replaced.Output_Partial = Canonical_After.Output_Partial
        and then Replaced.Stdout_Truncated = Canonical_After.Stdout_Truncated
        and then Replaced.Stderr_Truncated = Canonical_After.Stderr_Truncated;
   end Assert_Latest_Build_Output_Details_Final_Replace_Only_Frozen;

   function Assert_Latest_Build_Output_Details_Final_No_History
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Output_Details_Not_History (Details)
        and then not Has_Build_History_Field (Details);
   end Assert_Latest_Build_Output_Details_Final_No_History;

   function Assert_Latest_Build_Output_Details_Final_Not_Rerun_State
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Latest_Build_Output_Details_Not_Rerun_State (Details);
   end Assert_Latest_Build_Output_Details_Final_Not_Rerun_State;

   function Assert_Latest_Build_Output_Details_Final_Not_Process_Control
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Output_Details_Not_Process_Control (Details);
   end Assert_Latest_Build_Output_Details_Final_Not_Process_Control;

   function Assert_Latest_Build_Output_Details_Final_Not_Output_Log
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Latest_Build_Output_Details_Not_Output_Log (Details);
   end Assert_Latest_Build_Output_Details_Final_Not_Output_Log;

   function Assert_Latest_Build_Output_Details_Final_Not_Diagnostics_Owner
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Latest_Build_Output_Details_Not_Diagnostics_Owner (Details);
   end Assert_Latest_Build_Output_Details_Final_Not_Diagnostics_Owner;

   function Assert_Latest_Build_Output_Details_Final_Render_Boundary
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Latest_Build_Output_Details_Render_Cleanup (Details);
   end Assert_Latest_Build_Output_Details_Final_Render_Boundary;

   function Assert_Latest_Build_Output_Details_Final_Persistence_Excluded
     (Details : Latest_Build_Output_Details) return Boolean
   is
   begin
      return Assert_Latest_Build_Output_Details_Persistence_Excluded (Details);
   end Assert_Latest_Build_Output_Details_Final_Persistence_Excluded;

   function Assert_Public_Build_Output_Details_Final_Freeze_Coherent
     (Details : Latest_Build_Output_Details) return Boolean
   is
      Canonical : constant Latest_Build_Output_Details :=
        Clear_Stale_Build_Output_Details_Fields (Details);
   begin
      return Assert_Public_Build_Output_Details_Canonical_Coherent (Canonical)
        and then Assert_Latest_Build_Output_Details_Final_Ownership_Frozen (Canonical)
        and then Assert_Latest_Build_Output_Details_Final_Shape_Frozen (Canonical)
        and then Assert_Latest_Build_Output_Details_Final_Mapping_Frozen (Canonical)
        and then Assert_Latest_Build_Output_Details_Final_No_Output_Frozen (Canonical)
        and then Assert_Latest_Build_Output_Details_Final_No_History (Canonical)
        and then Assert_Latest_Build_Output_Details_Final_Not_Rerun_State (Canonical)
        and then Assert_Latest_Build_Output_Details_Final_Not_Process_Control (Canonical)
        and then Assert_Latest_Build_Output_Details_Final_Not_Output_Log (Canonical)
        and then Assert_Latest_Build_Output_Details_Final_Not_Diagnostics_Owner (Canonical)
        and then Assert_Latest_Build_Output_Details_Final_Render_Boundary (Canonical)
        and then Assert_Latest_Build_Output_Details_Final_Persistence_Excluded (Canonical);
   end Assert_Public_Build_Output_Details_Final_Freeze_Coherent;


   function Assert_Build_Output_Details_Useful_For_Build_UI
     (Details : Latest_Build_Output_Details) return Boolean
   is
      Snapshot : constant Latest_Build_Output_Details_Render_Snapshot :=
        Render_Snapshot (Details);
   begin
      if not Details.Has_Output_Details then
         return not Snapshot.Output_Details_Available
           and then Assert_Public_Build_Output_Details_Final_Freeze_Coherent
             (Details);
      end if;

      return Length (Snapshot.Output_Details_Status_Label) > 0
        and then Length (Snapshot.Output_Details_Runner_Status_Label) > 0
        and then Length (Snapshot.Output_Details_Limit_Label) > 0
        and then Length (Snapshot.No_Output_Label) > 0
        and then Length (Snapshot.Stdout_Truncation_Label) > 0
        and then Length (Snapshot.Stderr_Truncation_Label) > 0
        and then Length (Snapshot.Partial_Output_Label) > 0
        and then (Snapshot.Stdout_Available
                  or else Length (Snapshot.Stdout_No_Output_Label) > 0)
        and then (Snapshot.Stderr_Available
                  or else Length (Snapshot.Stderr_No_Output_Label) > 0)
        and then Assert_Public_Build_Output_Details_Final_Freeze_Coherent
          (Details);
   end Assert_Build_Output_Details_Useful_For_Build_UI;

end Editor.Build_Output_Details;
