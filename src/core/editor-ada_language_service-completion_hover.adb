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

with Editor.Ada_Language_Service.Navigation; use Editor.Ada_Language_Service.Navigation;
with Editor.Ada_Language_Service.Requests; use Editor.Ada_Language_Service.Requests;

package body Editor.Ada_Language_Service.Completion_Hover is

   use type Editor.Ada_Language_Model.Symbol_Kind;

   Max_Service_Targets : constant Positive := 200;

   function Target_Status_Result
     (Status : Service_Status) return Language_Target
   is
      Result : Language_Target;
   begin
      Result.Status := Status;
      return Result;
   end Target_Status_Result;

   function Target_Set_Status_Result
     (Status : Service_Status) return Language_Target_Set
   is
      Result : Language_Target_Set;
   begin
      Result.Status := Status;
      return Result;
   end Target_Set_Status_Result;

   function Completion_Status_Result
     (Status : Service_Status) return Completion_Result
   is
      Result : Completion_Result;
   begin
      Result.Status := Status;
      return Result;
   end Completion_Status_Result;

   function Hover_Status_Result
     (Status : Service_Status) return Hover_Result
   is
      Result : Hover_Result;
   begin
      Result.Status := Status;
      return Result;
   end Hover_Status_Result;

   function Rename_Status_Result
     (Status : Service_Status) return Rename_Preview
   is
      Result : Rename_Preview;
   begin
      Result.Status := Status;
      return Result;
   end Rename_Status_Result;

   function Contains_Query (Text, Query : String) return Boolean is
      Normal_Text  : constant String :=
        Editor.Ada_Language_Model.Normalize_Name (Text);
      Normal_Query : constant String :=
        Editor.Ada_Language_Model.Normalize_Name (Query);
   begin
      if Normal_Query'Length = 0 then
         return True;
      end if;

      return Ada.Strings.Unbounded.Index
        (To_Unbounded_String (Normal_Text), Normal_Query) > 0;
   end Contains_Query;

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

   function Is_Identifier_Start (C : Character) return Boolean is
   begin
      return (C >= 'A' and then C <= 'Z')
        or else (C >= 'a' and then C <= 'z');
   end Is_Identifier_Start;

   function Is_Identifier_Part (C : Character) return Boolean is
   begin
      return Is_Identifier_Start (C)
        or else (C >= '0' and then C <= '9')
        or else C = '_';
   end Is_Identifier_Part;

   function Is_Simple_Ada_Identifier (Name : String) return Boolean
   is
      Previous_Underscore : Boolean := False;
   begin
      if Name'Length = 0
        or else not Is_Identifier_Start (Name (Name'First))
        or else Editor.Syntax.Is_Keyword (Name)
      then
         return False;
      end if;

      for I in Name'Range loop
         if not Is_Identifier_Part (Name (I)) then
            return False;
         elsif Name (I) = '_' then
            if Previous_Underscore or else I = Name'Last then
               return False;
            end if;
            Previous_Underscore := True;
         else
            Previous_Underscore := False;
         end if;
      end loop;

      return True;
   end Is_Simple_Ada_Identifier;

   function Same_Buffer_Path
     (Key          : Editor.Ada_Project_Index.Indexed_File_Key;
      Path         : String;
      Buffer_Token : Natural) return Boolean is
   begin
      return Same_Path (To_String (Key.Path), Path)
        and then Key.Buffer_Token = Buffer_Token;
   end Same_Buffer_Path;

   function Same_Current_Key
     (Key                  : Editor.Ada_Project_Index.Indexed_File_Key;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Boolean is
   begin
      return Same_Path (To_String (Key.Path), Path)
        and then Key.Buffer_Token = Buffer_Token
        and then Key.Buffer_Revision = Buffer_Revision
        and then Key.Lifecycle_Generation = Lifecycle_Generation
        and then Key.Fingerprint = Analysis_Fingerprint;
   end Same_Current_Key;

   function Complete
     (Service : Service_State;
      Prefix  : String;
      Limit   : Positive := 50) return Completion_Result
   is
      Result : Completion_Result;
      Ordered_Items : Completion_Item_Vectors.Vector;

      function Less (Left, Right : Completion_Item) return Boolean
      is
         Left_Label  : constant String :=
           Editor.Ada_Language_Model.Normalize_Name (To_String (Left.Label));
         Right_Label : constant String :=
           Editor.Ada_Language_Model.Normalize_Name (To_String (Right.Label));
         Left_Path   : constant String := To_String (Left.Target.Path);
         Right_Path  : constant String := To_String (Right.Target.Path);
      begin
         if Left_Label /= Right_Label then
            return Left_Label < Right_Label;
         elsif Left_Path /= Right_Path then
            return Left_Path < Right_Path;
         elsif Left.Target.Line /= Right.Target.Line then
            return Left.Target.Line < Right.Target.Line;
         else
            return Left.Target.Column < Right.Target.Column;
         end if;
      end Less;

      function Same_Label (Left, Right : Completion_Item) return Boolean is
      begin
         return Editor.Ada_Language_Model.Normalize_Name (To_String (Left.Label)) =
           Editor.Ada_Language_Model.Normalize_Name (To_String (Right.Label));
      end Same_Label;

      procedure Insert_Ordered (Item : Completion_Item) is
      begin
         if not Ordered_Items.Is_Empty then
            for I in Ordered_Items.First_Index .. Ordered_Items.Last_Index loop
               if Same_Label (Ordered_Items (I), Item) then
                  if Less (Item, Ordered_Items (I)) then
                     Ordered_Items.Delete (I);
                     exit;
                  else
                     return;
                  end if;
               end if;
            end loop;
         end if;

         if Ordered_Items.Is_Empty then
            Ordered_Items.Append (Item);
            return;
         end if;

         for I in Ordered_Items.First_Index .. Ordered_Items.Last_Index loop
            if Less (Item, Ordered_Items (I)) then
               Ordered_Items.Insert (I, Item);
               if Natural (Ordered_Items.Length) > Limit then
                  Ordered_Items.Delete_Last;
               end if;
               return;
            end if;
         end loop;

         if Natural (Ordered_Items.Length) < Limit then
            Ordered_Items.Append (Item);
         end if;
      end Insert_Ordered;
   begin
      if Editor.Ada_Project_Index.Overflowed (Service.Index) then
         Result.Status := Service_Overflow;
         return Result;
      else
         Result.Status := Service_Unavailable;
      end if;

      for F in 1 .. Editor.Ada_Project_Index.File_Count (Service.Index) loop
         declare
            Key : constant Editor.Ada_Project_Index.Indexed_File_Key :=
              Editor.Ada_Project_Index.File_Key_At (Service.Index, F);
            Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
              Editor.Ada_Project_Index.File_Analysis_At (Service.Index, F);
         begin
            for S in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
               declare
                  Symbol : constant Editor.Ada_Language_Model.Symbol_Info :=
                    Editor.Ada_Language_Model.Symbol_At (Analysis, S);
                  Label  : constant String := To_String (Symbol.Name);
               begin
                  if Label'Length > 0
                    and then Starts_With (Label, Prefix)
                  then
                     Insert_Ordered
                       (Completion_Item'
                          (Label  => Symbol.Name,
                           Detail => To_Unbounded_String
                             (Editor.Ada_Project_Index.Navigation_Candidate_Detail_Label
                                ((Path   => Key.Path,
                                  Key    => Key,
                                  Symbol => Symbol))),
                           Kind   => Symbol.Kind,
                           Target =>
                             (Path   => Key.Path,
                              Line   => Symbol.Source_Span.Start_Line,
                              Column => Symbol.Source_Span.Start_Column),
                           Key    => Key));
                  end if;
               end;
            end loop;
         end;
      end loop;

      for Item of Ordered_Items loop
         Result.Items.Append (Item);
         Result.Status := Service_Success;
         exit when Natural (Result.Items.Length) >= Limit;
      end loop;

      return Result;
   end Complete;

   function Request_Complete
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Prefix  : String;
      Limit   : Positive := 50) return Completion_Result
   is
      Result : Completion_Result;
   begin
      if not Semantic_Request_Is_Current
        (Service, Id, Semantic_Request_Completion,
         Semantic_Request_Query_Key
           (Semantic_Request_Completion, Prefix,
            Detail => Positive'Image (Limit)))
      then
         return Completion_Status_Result (Request_Rejected_Status (Service, Id));
      end if;

      Result := Complete (Service, Prefix, Limit);
      Finish_Semantic_Request (Service, Id, Result.Status);
      return Result;
   end Request_Complete;

   function Complete_Current
     (Service              : Service_State;
      Prefix               : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural;
      Limit                : Positive := 50) return Completion_Result
   is
      Result        : Completion_Result;
      Ordered_Items : Completion_Item_Vectors.Vector;
      Saw_Stale     : Boolean := False;
      Saw_Current    : Boolean := False;

      function Key_Is_Current
        (Key : Editor.Ada_Project_Index.Indexed_File_Key) return Boolean is
      begin
         return Same_Current_Key
           (Key, Path, Buffer_Token, Buffer_Revision,
            Lifecycle_Generation, Analysis_Fingerprint);
      end Key_Is_Current;

      function Key_Is_Stale_Same_Buffer
        (Key : Editor.Ada_Project_Index.Indexed_File_Key) return Boolean is
      begin
         return Same_Path (To_String (Key.Path), Path)
           and then Key.Buffer_Token = Buffer_Token
           and then not Key_Is_Current (Key);
      end Key_Is_Stale_Same_Buffer;

      function Less (Left, Right : Completion_Item) return Boolean
      is
         Left_Label  : constant String :=
           Editor.Ada_Language_Model.Normalize_Name (To_String (Left.Label));
         Right_Label : constant String :=
           Editor.Ada_Language_Model.Normalize_Name (To_String (Right.Label));
         Left_Path   : constant String := To_String (Left.Target.Path);
         Right_Path  : constant String := To_String (Right.Target.Path);
      begin
         if Left_Label /= Right_Label then
            return Left_Label < Right_Label;
         elsif Left_Path /= Right_Path then
            return Left_Path < Right_Path;
         elsif Left.Target.Line /= Right.Target.Line then
            return Left.Target.Line < Right.Target.Line;
         else
            return Left.Target.Column < Right.Target.Column;
         end if;
      end Less;

      function Same_Label (Left, Right : Completion_Item) return Boolean is
      begin
         return Editor.Ada_Language_Model.Normalize_Name (To_String (Left.Label)) =
           Editor.Ada_Language_Model.Normalize_Name (To_String (Right.Label));
      end Same_Label;

      procedure Insert_Ordered (Item : Completion_Item) is
      begin
         if not Ordered_Items.Is_Empty then
            for I in Ordered_Items.First_Index .. Ordered_Items.Last_Index loop
               if Same_Label (Ordered_Items (I), Item) then
                  if Less (Item, Ordered_Items (I)) then
                     Ordered_Items.Delete (I);
                     exit;
                  else
                     return;
                  end if;
               end if;
            end loop;
         end if;

         if Ordered_Items.Is_Empty then
            Ordered_Items.Append (Item);
            return;
         end if;

         for I in Ordered_Items.First_Index .. Ordered_Items.Last_Index loop
            if Less (Item, Ordered_Items (I)) then
               Ordered_Items.Insert (I, Item);
               if Natural (Ordered_Items.Length) > Limit then
                  Ordered_Items.Delete_Last;
               end if;
               return;
            end if;
         end loop;

         if Natural (Ordered_Items.Length) < Limit then
            Ordered_Items.Append (Item);
         end if;
      end Insert_Ordered;
   begin
      if Editor.Ada_Project_Index.Overflowed (Service.Index) then
         Result.Status := Service_Overflow;
         return Result;
      end if;

      Result.Status := Service_Unavailable;

      for F in 1 .. Editor.Ada_Project_Index.File_Count (Service.Index) loop
         declare
            Key : constant Editor.Ada_Project_Index.Indexed_File_Key :=
              Editor.Ada_Project_Index.File_Key_At (Service.Index, F);
         begin
            if Key_Is_Current (Key) then
               Saw_Current := True;
               declare
                  Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
                    Editor.Ada_Project_Index.File_Analysis_At (Service.Index, F);
               begin
                  if Editor.Ada_Language_Model.Overflowed (Analysis) then
                     Result.Status := Service_Overflow;
                     return Result;
                  end if;

                  for S in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
                     declare
                        Symbol : constant Editor.Ada_Language_Model.Symbol_Info :=
                          Editor.Ada_Language_Model.Symbol_At (Analysis, S);
                        Label  : constant String := To_String (Symbol.Name);
                     begin
                        if Label'Length > 0
                          and then Starts_With (Label, Prefix)
                        then
                           Insert_Ordered
                             (Completion_Item'
                                (Label  => Symbol.Name,
                                 Detail => To_Unbounded_String
                                   (Editor.Ada_Project_Index.Navigation_Candidate_Detail_Label
                                      ((Path   => Key.Path,
                                        Key    => Key,
                                        Symbol => Symbol))),
                                 Kind   => Symbol.Kind,
                                 Target =>
                                   (Path   => Key.Path,
                                    Line   => Symbol.Source_Span.Start_Line,
                                    Column => Symbol.Source_Span.Start_Column),
                                 Key    => Key));
                        end if;
                     end;
                  end loop;
               end;
            elsif Key_Is_Stale_Same_Buffer (Key) then
               Saw_Stale := True;
            else
               declare
                  Analysis : constant Editor.Ada_Language_Model.Analysis_Result :=
                    Editor.Ada_Project_Index.File_Analysis_At (Service.Index, F);
               begin
                  if Editor.Ada_Language_Model.Overflowed (Analysis) then
                     Result.Status := Service_Overflow;
                     return Result;
                  end if;

                  for S in 1 .. Editor.Ada_Language_Model.Symbol_Count (Analysis) loop
                     declare
                        Symbol : constant Editor.Ada_Language_Model.Symbol_Info :=
                          Editor.Ada_Language_Model.Symbol_At (Analysis, S);
                        Label  : constant String := To_String (Symbol.Name);
                     begin
                        if Label'Length > 0
                          and then Starts_With (Label, Prefix)
                        then
                           Insert_Ordered
                             (Completion_Item'
                                (Label  => Symbol.Name,
                                 Detail => To_Unbounded_String
                                   (Editor.Ada_Project_Index.Navigation_Candidate_Detail_Label
                                      ((Path   => Key.Path,
                                        Key    => Key,
                                        Symbol => Symbol))),
                                 Kind   => Symbol.Kind,
                                 Target =>
                                   (Path   => Key.Path,
                                    Line   => Symbol.Source_Span.Start_Line,
                                    Column => Symbol.Source_Span.Start_Column),
                                 Key    => Key));
                        end if;
                     end;
                  end loop;
               end;
            end if;
         end;
      end loop;

      if not Saw_Current and then Saw_Stale then
         Result.Status := Service_Stale;
      elsif Saw_Current then
         for Item of Ordered_Items loop
            Result.Items.Append (Item);
            Result.Status := Service_Success;
            exit when Natural (Result.Items.Length) >= Limit;
         end loop;
      end if;

      return Result;
   end Complete_Current;

   function Request_Complete_Current
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Prefix               : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural;
      Limit                : Positive := 50) return Completion_Result
   is
      Result : Completion_Result;
   begin
      if not Semantic_Request_Is_Current
        (Service, Id, Semantic_Request_Completion,
         Semantic_Current_Request_Query_Key
           (Semantic_Request_Completion, Prefix, Path, Buffer_Token,
            Buffer_Revision, Lifecycle_Generation, Analysis_Fingerprint,
            Detail => Positive'Image (Limit)))
      then
         return Completion_Status_Result (Request_Rejected_Status (Service, Id));
      end if;

      Result := Complete_Current
        (Service, Prefix, Path, Buffer_Token, Buffer_Revision,
         Lifecycle_Generation, Analysis_Fingerprint, Limit);
      Finish_Semantic_Request (Service, Id, Result.Status);
      return Result;
   end Request_Complete_Current;

   function Hover
     (Service : Service_State;
      Name    : String) return Hover_Result
   is
      Target : constant Language_Target :=
        Goto_Declaration
          (Service, Name, Editor.Ada_Language_Model.Symbol_Unknown);
      Matches : constant Editor.Ada_Project_Index.Index_Resolution_Result :=
        Editor.Ada_Project_Index.Resolve
          (Service.Index, Name, Max_Matches => 2);
      Result : Hover_Result;
   begin
      if Target.Status = Service_Success then
         Result.Status := Service_Success;
         Result.Label := Target.Name;
         Result.Detail := Target.Detail;
         Result.Target := Target.Target;
         Result.Key := Target.Key;
         return Result;
      end if;

      if Matches.Overflow then
         Result.Status := Service_Overflow;
      elsif Matches.Matches.Is_Empty then
         Result.Status := Service_Unavailable;
      else
         declare
            First : constant Editor.Ada_Project_Index.Indexed_Symbol :=
              Matches.Matches (Matches.Matches.First_Index);
         begin
            Result.Status :=
              (if Natural (Matches.Matches.Length) = 1 then Service_Success
               else Service_Ambiguous);
            Result.Label := First.Symbol.Name;
            Result.Detail := To_Unbounded_String
              (Editor.Ada_Project_Index.Navigation_Candidate_Detail_Label
                 (First));
            Result.Target :=
              (Path   => First.Path,
               Line   => First.Symbol.Source_Span.Start_Line,
               Column => First.Symbol.Source_Span.Start_Column);
            Result.Key := First.Key;
         end;
      end if;

      return Result;
   end Hover;

   function Request_Hover
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Name    : String) return Hover_Result
   is
      Result : Hover_Result;
   begin
      if not Semantic_Request_Is_Current
        (Service, Id, Semantic_Request_Hover, Name)
      then
         return Hover_Status_Result (Request_Rejected_Status (Service, Id));
      end if;

      Result := Hover (Service, Name);
      Finish_Semantic_Request (Service, Id, Result.Status);
      return Result;
   end Request_Hover;

   function Hover_Current
     (Service              : Service_State;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Hover_Result
   is
      Current_Matches : constant Editor.Ada_Project_Index.Index_Resolution_Result :=
        Editor.Ada_Project_Index.Resolve_Current
          (Service.Index, Name, Path, Buffer_Token, Buffer_Revision,
           Lifecycle_Generation, Analysis_Fingerprint);
      Current_Snapshot_Available : constant Boolean :=
        Editor.Ada_Project_Index.Contains_Current
          (Service.Index, Path, Buffer_Token, Buffer_Revision,
           Lifecycle_Generation, Analysis_Fingerprint);
      Result : Hover_Result;
   begin
      if Current_Matches.Overflow then
         Result.Status := Service_Overflow;
         return Result;
      elsif not Current_Matches.Matches.Is_Empty then
         declare
            First : constant Editor.Ada_Project_Index.Indexed_Symbol :=
              Current_Matches.Matches (Current_Matches.Matches.First_Index);
         begin
            Result.Status :=
              (if Natural (Current_Matches.Matches.Length) = 1
               then Service_Success
               else Service_Ambiguous);
            Result.Label := First.Symbol.Name;
            Result.Detail := To_Unbounded_String
              (Editor.Ada_Project_Index.Navigation_Candidate_Detail_Label
                 (First));
            Result.Target :=
              (Path   => First.Path,
               Line   => First.Symbol.Source_Span.Start_Line,
               Column => First.Symbol.Source_Span.Start_Column);
            Result.Key := First.Key;
         end;
         return Result;
      elsif Current_Snapshot_Available then
         Result.Status := Service_Unavailable;
         return Result;
      end if;

      declare
         Project_Matches : constant Editor.Ada_Project_Index.Index_Resolution_Result :=
           Editor.Ada_Project_Index.Resolve
             (Service.Index, Name, Max_Matches => Max_Service_Targets);
      begin
         if Project_Matches.Overflow then
            Result.Status := Service_Overflow;
         elsif Project_Matches.Matches.Is_Empty then
            Result.Status := Service_Unavailable;
         else
            Result.Status := Service_Unavailable;
            for Match of Project_Matches.Matches loop
               if Same_Buffer_Path (Match.Key, Path, Buffer_Token)
               then
                  Result.Status := Service_Stale;
                  exit;
               end if;
            end loop;
         end if;
      end;

      return Result;
   end Hover_Current;

   function Request_Hover_Current
     (Service              : in out Service_State;
      Id                   : Semantic_Request_Id;
      Name                 : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural) return Hover_Result
   is
      Result : Hover_Result;
   begin
      if not Semantic_Request_Is_Current
        (Service, Id, Semantic_Request_Hover,
         Semantic_Current_Request_Query_Key
           (Semantic_Request_Hover, Name, Path, Buffer_Token,
            Buffer_Revision, Lifecycle_Generation, Analysis_Fingerprint))
      then
         return Hover_Status_Result (Request_Rejected_Status (Service, Id));
      end if;

      Result := Hover_Current
        (Service, Name, Path, Buffer_Token, Buffer_Revision,
         Lifecycle_Generation, Analysis_Fingerprint);
      Finish_Semantic_Request (Service, Id, Result.Status);
      return Result;
   end Request_Hover_Current;

end Editor.Ada_Language_Service.Completion_Hover;
