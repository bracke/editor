with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Action_Router;
with Editor.Ada_Diagnostic_Navigation;
with Editor.Ada_Diagnostic_Panel_Projection;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Diagnostic_Quick_Fix_Skeleton;
with Editor.Ada_Diagnostic_Status_Line;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.External_Producers.Diagnostic_Line_Parsing;
with Editor.External_Producers.Diagnostic_Text_Lines;
with Editor.External_Producers.Diagnostics_Types;
with Editor.Syntax;

with Editor.Ada_Language_Service.Diagnostics;

package body Editor.Ada_Language_Service.Indexing is

   use type Editor.Ada_Language_Model.Symbol_Kind;

   function Mix (Left : Natural; Right : Natural) return Natural is
      Modulus : constant Natural := 1_000_003;
   begin
      return
        (((Left mod Modulus) * 131)
         + (Right mod Modulus)
         + 16#9E37#) mod Modulus;
   end Mix;

   function Text_Fingerprint (Text : String) return Natural is
      Result : Natural := 0;
   begin
      for Ch of Text loop
         Result := Mix (Result, Character'Pos (Ch) + 1);
      end loop;
      return Result;
   end Text_Fingerprint;

   function Starts_With (Text, Prefix : String) return Boolean is
      Normal_Text   : constant String :=
        Editor.Ada_Language_Model.Normalize_Name (Text);
      Normal_Prefix : constant String :=
        Editor.Ada_Language_Model.Normalize_Name (Prefix);
   begin
      if Normal_Prefix'Length = 0 then
         return True;
      end if;

      return Normal_Text'Length >= Normal_Prefix'Length
        and then Normal_Text
          (Normal_Text'First .. Normal_Text'First + Normal_Prefix'Length - 1)
        = Normal_Prefix;
   end Starts_With;

   function Normalized_Path (Text : String) return String is
      Result   : String := Text;
      Write    : Natural := Result'First;
      Last     : Natural;
      Prev_Sep : Boolean := False;
   begin
      if Text'Length = 0 then
         return "";
      end if;

      for I in Text'Range loop
         declare
            Ch : Character := Text (I);
         begin
            if Character'Pos (Ch) = 16#5C# then
               Ch := '/';
            end if;

            if Ch = '/' then
               if not Prev_Sep then
                  Result (Write) := Ch;
                  Write := Write + 1;
               end if;
               Prev_Sep := True;
            else
               Result (Write) := Ch;
               Write := Write + 1;
               Prev_Sep := False;
            end if;
         end;
      end loop;

      if Write = Result'First then
         return "";
      end if;

      Last := Write - 1;
      while Last >= Result'First and then Result (Last) = '/' loop
         if Last = 0 then
            exit;
         end if;
         Last := Last - 1;
      end loop;

      if Last < Result'First then
         return "";
      end if;

      return Result (Result'First .. Last);
   end Normalized_Path;

   function Same_Path (Left, Right : String) return Boolean is
   begin
      return Normalized_Path (Left) = Normalized_Path (Right);
   end Same_Path;

   function Path_Matches_Label (Path, Label : String) return Boolean
   is
      Normal_Path  : constant String := Normalized_Path (Path);
      Normal_Label : constant String := Normalized_Path (Label);

      function Component_Suffix_Matches
        (Longer  : String;
         Shorter : String) return Boolean
      is
         Offset : Natural;
      begin
         if Longer'Length <= Shorter'Length then
            return False;
         end if;

         Offset := Longer'Last - Shorter'Length + 1;
         return Offset > Longer'First
           and then Longer (Offset - 1) = '/'
           and then Longer (Offset .. Longer'Last) = Shorter;
      end Component_Suffix_Matches;
   begin
      if Normal_Path'Length = 0 or else Normal_Label'Length = 0 then
         return False;
      elsif Normal_Path = Normal_Label then
         return True;
      end if;

      return Component_Suffix_Matches (Normal_Path, Normal_Label)
        or else Component_Suffix_Matches (Normal_Label, Normal_Path);
   end Path_Matches_Label;

   function Has_Prefix (Text, Prefix : String) return Boolean is
   begin
      return Prefix'Length = 0
        or else (Text'Length >= Prefix'Length
                 and then Text (Text'First .. Text'First + Prefix'Length - 1) =
                   Prefix);
   end Has_Prefix;

   procedure Clear (Service : in out Service_State) is
   begin
      Editor.Ada_Project_Index.Clear (Service.Index);
      Clear_Semantic_Diagnostics (Service);
      Clear_Compiler_Backend (Service);
      Service.Next_Request_Id := No_Semantic_Request;
      Service.Active_Request := (others => <>);
      Service.Previous_Request := (others => <>);
   end Clear;

   function From_Index
     (Index : Editor.Ada_Project_Index.Index_State) return Service_State is
   begin
      return
        (Index                => Index,
        Semantic_Diagnostics => Semantic_Diagnostic_Vectors.Empty_Vector,
        Semantic_State       => (others => <>),
         Compiler_Diagnostics => Compiler_Diagnostic_Vectors.Empty_Vector,
         Compiler_State       => (others => <>),
         Next_Request_Id      => No_Semantic_Request,
         Active_Request       => (others => <>),
         Previous_Request     => (others => <>));
   end From_Index;

   procedure Put_Index
     (Service : in out Service_State;
      Index   : Editor.Ada_Project_Index.Index_State) is
      Old_Fingerprint : constant Natural :=
        Editor.Ada_Project_Index.Fingerprint (Service.Index);
      New_Fingerprint : constant Natural :=
        Editor.Ada_Project_Index.Fingerprint (Index);
   begin
      Service.Index := Index;
      if Service.Active_Request.Status = Semantic_Request_Pending
        and then Old_Fingerprint /= New_Fingerprint
      then
         Service.Active_Request.Status := Semantic_Request_Stale;
         Service.Active_Request.Result_Status := Service_Stale;
      end if;
   end Put_Index;

   function Project_Index
     (Service : Service_State) return Editor.Ada_Project_Index.Index_State is
   begin
      return Service.Index;
   end Project_Index;

   procedure Put_Buffer_Analysis
     (Service              : in out Service_State;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis             : Editor.Ada_Language_Model.Analysis_Result) is
   begin
      Editor.Ada_Project_Index.Put_Analysis
        (Service.Index, Path, Buffer_Token, Buffer_Revision,
         Lifecycle_Generation, Analysis);
      if Service.Active_Request.Status = Semantic_Request_Pending
        and then Service.Active_Request.Index_Fingerprint /=
          Editor.Ada_Project_Index.Fingerprint (Service.Index)
      then
         Service.Active_Request.Status := Semantic_Request_Stale;
         Service.Active_Request.Result_Status := Service_Stale;
      end if;
   end Put_Buffer_Analysis;

   procedure Invalidate_Path (Service : in out Service_State; Path : String) is
   begin
      Editor.Ada_Project_Index.Invalidate_Path (Service.Index, Path);
      if Service.Active_Request.Status = Semantic_Request_Pending then
         Service.Active_Request.Status := Semantic_Request_Stale;
         Service.Active_Request.Result_Status := Service_Stale;
      end if;
   end Invalidate_Path;

   procedure Invalidate_Path_Subtree
     (Service : in out Service_State;
      Root_Path : String) is
   begin
      Editor.Ada_Project_Index.Invalidate_Path_Subtree
        (Service.Index, Root_Path);
      if Service.Active_Request.Status = Semantic_Request_Pending then
         Service.Active_Request.Status := Semantic_Request_Stale;
         Service.Active_Request.Result_Status := Service_Stale;
      end if;
   end Invalidate_Path_Subtree;

   procedure Invalidate_Buffer
     (Service : in out Service_State;
      Buffer_Token : Natural) is
   begin
      Editor.Ada_Project_Index.Invalidate_Buffer (Service.Index, Buffer_Token);
      if Service.Active_Request.Status = Semantic_Request_Pending then
         Service.Active_Request.Status := Semantic_Request_Stale;
         Service.Active_Request.Result_Status := Service_Stale;
      end if;
   end Invalidate_Buffer;

   procedure Invalidate_Lifecycle
     (Service : in out Service_State;
      Lifecycle_Generation : Natural) is
   begin
      Editor.Ada_Project_Index.Invalidate_Lifecycle
        (Service.Index, Lifecycle_Generation);
      if Service.Active_Request.Status = Semantic_Request_Pending then
         Service.Active_Request.Status := Semantic_Request_Stale;
         Service.Active_Request.Result_Status := Service_Stale;
      end if;
   end Invalidate_Lifecycle;

   function Status (Service : Service_State) return Index_Status is
   begin
      return
        (File_Count   => Editor.Ada_Project_Index.File_Count (Service.Index),
         Unit_Count   => Editor.Ada_Project_Index.Unit_Count (Service.Index),
         Symbol_Count => Editor.Ada_Project_Index.Symbol_Count (Service.Index),
         Fingerprint  => Editor.Ada_Project_Index.Fingerprint (Service.Index),
         Overflowed   => Editor.Ada_Project_Index.Overflowed (Service.Index));
   end Status;

   function Status
     (Index : Editor.Ada_Project_Index.Index_State) return Index_Status is
   begin
      return Status (From_Index (Index));
   end Status;

   function Semantic_Request_Query_Key
     (Kind            : Semantic_Request_Kind;
      Name            : String;
      Profile_Summary : String := "";
      Detail          : String := "") return String
   is
      Separator : constant Character := Character'Val (31);
   begin
      case Kind is
         when Semantic_Request_Goto_Declaration =>
            if Detail'Length > 0 then
               return Name & Separator & Detail;
            end if;
         when Semantic_Request_Goto_Body | Semantic_Request_Goto_Spec =>
            if Profile_Summary'Length > 0 or else Detail'Length > 0 then
               return Name & Separator & Profile_Summary &
                 Separator & Detail;
            end if;
         when Semantic_Request_Completion | Semantic_Request_Rename =>
            if Detail'Length > 0 then
               return Name & Separator & Detail;
            end if;
         when others =>
            null;
      end case;

      return Name;
   end Semantic_Request_Query_Key;

   function Semantic_Current_Request_Query_Key
     (Kind                 : Semantic_Request_Kind;
      Query                : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural;
      Detail               : String := "") return String
   is
      Separator : constant Character := Character'Val (30);
   begin
      return Semantic_Request_Kind'Image (Kind) &
        Separator & Query &
        Separator & Path &
        Separator & Natural'Image (Buffer_Token) &
        Separator & Natural'Image (Buffer_Revision) &
        Separator & Natural'Image (Lifecycle_Generation) &
        Separator & Natural'Image (Analysis_Fingerprint) &
        Separator & Detail;
   end Semantic_Current_Request_Query_Key;

   function Begin_Semantic_Request
     (Service : in out Service_State;
      Kind    : Semantic_Request_Kind;
      Query   : String := "") return Semantic_Request_Id
   is
   begin
      Service.Previous_Request := Service.Active_Request;
      if Service.Previous_Request.Status = Semantic_Request_Pending then
         Service.Previous_Request.Status := Semantic_Request_Superseded;
         Service.Previous_Request.Result_Status := Service_Stale;
      end if;

      if Service.Next_Request_Id = Semantic_Request_Id'Last then
         Service.Next_Request_Id := 1;
      else
         Service.Next_Request_Id := Service.Next_Request_Id + 1;
      end if;

      Service.Active_Request :=
        (Id                => Service.Next_Request_Id,
         Kind              => Kind,
         Status            => Semantic_Request_Pending,
         Query             => To_Unbounded_String (Query),
         Index_Fingerprint => Editor.Ada_Project_Index.Fingerprint
           (Service.Index),
         Result_Status     => Service_Unavailable);
      return Service.Active_Request.Id;
   end Begin_Semantic_Request;

   procedure Cancel_Semantic_Request
     (Service : in out Service_State;
      Id      : Semantic_Request_Id) is
   begin
      if Id /= No_Semantic_Request
        and then Service.Active_Request.Id = Id
        and then Service.Active_Request.Status = Semantic_Request_Pending
      then
         Service.Active_Request.Status := Semantic_Request_Cancelled;
         Service.Active_Request.Result_Status := Service_Unavailable;
      end if;
   end Cancel_Semantic_Request;

   function Active_Semantic_Request
     (Service : Service_State) return Semantic_Request_Status is
   begin
      return Service.Active_Request;
   end Active_Semantic_Request;

   function Previous_Semantic_Request
     (Service : Service_State) return Semantic_Request_Status is
   begin
      return Service.Previous_Request;
   end Previous_Semantic_Request;

   function Semantic_Request_Is_Current
     (Service : Service_State;
      Id      : Semantic_Request_Id) return Boolean is
   begin
      return Id /= No_Semantic_Request
        and then Service.Active_Request.Id = Id
        and then Service.Active_Request.Status = Semantic_Request_Pending
        and then Service.Active_Request.Index_Fingerprint =
          Editor.Ada_Project_Index.Fingerprint (Service.Index);
   end Semantic_Request_Is_Current;

   function Semantic_Request_Is_Current
     (Service : Service_State;
      Id      : Semantic_Request_Id;
      Kind    : Semantic_Request_Kind) return Boolean is
   begin
      return Semantic_Request_Is_Current (Service, Id)
        and then Service.Active_Request.Kind = Kind;
   end Semantic_Request_Is_Current;

   function Semantic_Request_Is_Current
     (Service : Service_State;
      Id      : Semantic_Request_Id;
      Kind    : Semantic_Request_Kind;
      Query   : String) return Boolean
   is
      Active_Query : constant String := To_String (Service.Active_Request.Query);
   begin
      return Semantic_Request_Is_Current (Service, Id, Kind)
        and then Active_Query = Query;
   end Semantic_Request_Is_Current;

   function Request_Rejected_Status
     (Service : Service_State;
      Id      : Semantic_Request_Id) return Service_Status
   is
   begin
      if Id = No_Semantic_Request
        or else Service.Active_Request.Id /= Id
        or else Service.Active_Request.Status = Semantic_Request_No_Request
      then
         return Service_Unavailable;
      elsif Service.Active_Request.Status = Semantic_Request_Cancelled then
         return Service_Unavailable;
      else
         return Service_Stale;
      end if;
   end Request_Rejected_Status;

   procedure Finish_Semantic_Request
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Status  : Service_Status)
   is
   begin
      if Id = No_Semantic_Request
        or else Service.Active_Request.Id /= Id
      then
         return;
      elsif Service.Active_Request.Status = Semantic_Request_Pending
        and then Service.Active_Request.Index_Fingerprint =
          Editor.Ada_Project_Index.Fingerprint (Service.Index)
      then
         Service.Active_Request.Status := Semantic_Request_Completed;
         Service.Active_Request.Result_Status := Status;
      elsif Service.Active_Request.Status = Semantic_Request_Pending then
         Service.Active_Request.Status := Semantic_Request_Stale;
         Service.Active_Request.Result_Status := Service_Stale;
      end if;
   end Finish_Semantic_Request;

   function Backend_Status
     (Service : Service_State) return Semantic_Backend_Status
   is
      Index_State : constant Index_Status := Status (Service);
      Semantic    : constant Semantic_Diagnostic_Status :=
        Service.Semantic_State;
      Compiler    : constant Compiler_Backend_Status :=
        Service.Compiler_State;
      Result      : Semantic_Backend_Status;
   begin
      Result.Internal_Index_Available :=
        Index_State.File_Count > 0 or else Index_State.Symbol_Count > 0;
      Result.Internal_Diagnostics_Active := Semantic.Diagnostic_Count > 0;
      Result.Compiler_Diagnostics_Active := Compiler.Diagnostic_Count > 0;
      Result.Compiler_Backend_Available := Compiler.Has_Run;
      Result.Navigation_From_Index := Result.Internal_Index_Available;
      Result.Diagnostics_From_Internal := Result.Internal_Diagnostics_Active;
      Result.Diagnostics_From_Compiler := Result.Compiler_Diagnostics_Active;
      Result.Semantic_Requests_Available := True;
      Result.Semantic_Requests_Cancellable :=
        Service.Active_Request.Status = Semantic_Request_Pending;
      Result.Active_Request_Id := Service.Active_Request.Id;
      Result.Active_Request_Kind := Service.Active_Request.Kind;
      Result.Active_Request_Status := Service.Active_Request.Status;
      Result.Previous_Request_Status := Service.Previous_Request.Status;

      if Result.Compiler_Diagnostics_Active then
         Result.Active_Backend := Semantic_Backend_GNAT_Compiler;
      else
         Result.Active_Backend := Semantic_Backend_Internal_Index;
      end if;

      Result.Fingerprint := Mix (Index_State.Fingerprint, Semantic.Fingerprint);
      Result.Fingerprint := Mix (Result.Fingerprint, Compiler.Fingerprint);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Semantic_Backend_Kind'Pos (Result.Active_Backend) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Internal_Index_Available) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Internal_Diagnostics_Active) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Compiler_Backend_Available) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Compiler_Diagnostics_Active) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Diagnostics_From_Internal) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Diagnostics_From_Compiler) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Semantic_Requests_Available) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Semantic_Requests_Cancellable) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint, Result.Active_Request_Id + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Semantic_Request_Kind'Pos (Result.Active_Request_Kind) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Semantic_Request_Status_Kind'Pos (Result.Active_Request_Status) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Semantic_Request_Status_Kind'Pos (Result.Previous_Request_Status) + 1);
      return Result;
   end Backend_Status;

   function Backend_Label
     (Status : Semantic_Backend_Status) return String
   is
   begin
      case Status.Active_Backend is
         when Semantic_Backend_Internal_Index =>
            return "internal-index";
         when Semantic_Backend_GNAT_Compiler =>
            return "gnat-compiler";
      end case;
   end Backend_Label;

   function Capabilities
     (Service : Service_State) return Language_Service_Capabilities
   is
      Backend : constant Semantic_Backend_Status := Backend_Status (Service);
      Result  : Language_Service_Capabilities;
      Index_Ready : constant Boolean :=
        Backend.Navigation_From_Index
        and then Editor.Ada_Project_Index.Symbol_Count (Service.Index) > 0;
   begin
      Result.Navigation_Ready := Index_Ready;
      Result.References_Ready := Index_Ready;
      Result.Workspace_Symbols_Ready := Index_Ready;
      Result.Completion_Ready := Index_Ready;
      Result.Hover_Ready := Index_Ready;
      Result.Rename_Preview_Ready := Index_Ready;
      Result.Internal_Diagnostics_Ready :=
        Backend.Diagnostics_From_Internal;
      Result.Compiler_Diagnostics_Ready :=
        Backend.Diagnostics_From_Compiler;
      Result.Request_Cancellation_Available :=
        Backend.Semantic_Requests_Cancellable;

      Result.Fingerprint := Backend.Fingerprint;
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Navigation_Supported) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Navigation_Ready) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.References_Supported) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.References_Ready) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Workspace_Symbols_Supported) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Workspace_Symbols_Ready) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Completion_Supported) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Completion_Ready) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Hover_Supported) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Hover_Ready) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Rename_Preview_Supported) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Rename_Preview_Ready) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Diagnostics_Supported) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Internal_Diagnostics_Ready) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Compiler_Diagnostics_Ready) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Request_Lifecycle_Supported) + 1);
      Result.Fingerprint := Mix
        (Result.Fingerprint,
         Boolean'Pos (Result.Request_Cancellation_Available) + 1);
      return Result;
   end Capabilities;

end Editor.Ada_Language_Service.Indexing;
