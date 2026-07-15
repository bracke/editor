with Editor.Test_Temp;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Syntax;
with Editor.Syntax_Cache;
with Editor.Syntax_Semantics;
with Editor.State;
with Editor.Render_Model;
with Editor.Buffers;
with Editor.Executor;
with Editor.Commands;
with Editor.Test_Helper;
with Editor.History;
with Text_Buffer;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Syntax_Cache.Tests is

   use type Editor.Syntax.Syntax_Kind;

   function Name (T : Syntax_Cache_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Syntax_Cache.Tests");
   end Name;

   procedure Test_Incremental_State_Propagation (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Cache : Editor.Syntax_Cache.Syntax_Cache;
      Changed : Boolean;
   begin
      Editor.Syntax_Cache.Set_Line_Count (Cache, 2);
      Editor.Syntax_Cache.Relex_Dirty_Line (Cache, 1, "S := ""open", Changed);
      Assert (Changed, "unterminated string should change line end state");
      Assert (Editor.Syntax_Cache.Is_Dirty (Cache, 2), "state change must dirty following line");
      Editor.Syntax_Cache.Relex_Dirty_Line (Cache, 2, "still string"";", Changed);
      Assert (not Editor.Syntax_Cache.Is_Dirty (Cache, 2), "relex clears dirty flag");
      Assert (Editor.Syntax_Cache.Tokens_For_Line (Cache, 1)'Length > 0, "tokens should be cached");
   end Test_Incremental_State_Propagation;

   procedure Test_Range_Dirty (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Cache : Editor.Syntax_Cache.Syntax_Cache;
   begin
      Editor.Syntax_Cache.Set_Line_Count (Cache, 3);
      Editor.Syntax_Cache.Mark_Range_Dirty (Cache, 2, 3);
      Assert (Editor.Syntax_Cache.Is_Dirty (Cache, 2), "line 2 dirty");
      Assert (Editor.Syntax_Cache.Is_Dirty (Cache, 3), "line 3 dirty");
   end Test_Range_Dirty;



   procedure Test_Render_Snapshot_Consumes_Syntax_Cache (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
      Saw_Keyword : Boolean := False;
   begin
      Editor.State.Init (S);
      Editor.State.Replace_Buffer_Contents (S, "procedure Draw is begin null; end Draw;");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      for I in 1 .. Snap.Syntax_Span_Count loop
         if Snap.Syntax_Spans (I).Kind = Editor.Syntax.Keyword then
            Saw_Keyword := True;
         end if;
      end loop;

      Assert (Snap.Syntax_Span_Count > 0, "render snapshot should expose cached syntax spans");
      Assert (Saw_Keyword, "render snapshot should carry lexical keyword spans");
   end Test_Render_Snapshot_Consumes_Syntax_Cache;




   procedure Test_Active_Buffer_Token_Mismatch_Clears_Syntax_Owner
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      S.Active_Buffer_Token := 10;
      Editor.State.Replace_Buffer_Contents
        (S, "procedure Owner_A is begin null; end Owner_A;");
      Editor.State.Prepare_Syntax_For_Visible_Range (S, 0, 0, True);
      Assert
        (S.Syntax_Source_Buffer_Token = 10,
         "initial syntax cache owner should match active buffer token");
      Assert
        (Editor.Syntax_Cache.Tokens_For_Line (S.Syntax_Cache, 1)'Length > 0,
         "initial owner should have cached tokens");

      S.Active_Buffer_Token := 20;
      Editor.State.Prepare_Syntax_For_Visible_Range (S, 0, 0, True);
      Assert
        (S.Syntax_Source_Buffer_Token = 20,
         "token mismatch should restamp syntax cache ownership");
      Assert
        (S.Syntax_Symbols_Buffer_Token = 20,
         "token mismatch should restamp semantic ownership");
      Assert
        (Editor.Syntax_Cache.Tokens_For_Line (S.Syntax_Cache, 1)'Length > 0,
         "restamped owner should rebuild deterministic cached tokens");
   end Test_Active_Buffer_Token_Mismatch_Clears_Syntax_Owner;

   procedure Test_Buffer_Switch_Does_Not_Reuse_Syntax_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Buffers.Buffer_Id;
      B : Editor.Buffers.Buffer_Id;
      Snap : Editor.Render_Model.Render_Snapshot;
      B_Saw_String : Boolean := False;
      B_Saw_Keyword : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Global_Add_File_Buffer
        (Editor.Test_Temp.Base & "/editor-syntax-a.adb", "editor-syntax-a.adb",
         "S := ""unterminated" & ASCII.LF & "still string"";", A);
      Editor.Buffers.Global_Add_File_Buffer
        (Editor.Test_Temp.Base & "/editor-syntax-b.adb", "editor-syntax-b.adb",
         "procedure Normal is" & ASCII.LF & "begin" & ASCII.LF & "   null;" & ASCII.LF & "end Normal;", B);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Syntax_Span_Count > 0, "first buffer should build syntax spans");

      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      for I in 1 .. Snap.Syntax_Span_Count loop
         if Snap.Syntax_Spans (I).Kind = Editor.Syntax.String_Literal then
            B_Saw_String := True;
         elsif Snap.Syntax_Spans (I).Kind = Editor.Syntax.Keyword then
            B_Saw_Keyword := True;
         end if;
      end loop;

      Assert (B_Saw_Keyword, "second buffer should lex its own Ada keywords");
      Assert (not B_Saw_String,
              "second buffer must not inherit unterminated string state from first buffer");
   end Test_Buffer_Switch_Does_Not_Reuse_Syntax_State;

   procedure Test_Cache_Line_Cap_Degrades_Safely
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Cache : Editor.Syntax_Cache.Syntax_Cache;
   begin
      Editor.Syntax_Cache.Set_Line_Count
        (Cache, Editor.Syntax_Cache.Max_Cached_Lines + 25);
      Assert
        (Editor.Syntax_Cache.Cached_Line_Count (Cache) =
           Editor.Syntax_Cache.Max_Cached_Lines,
         "cache must bound its internal line table explicitly");
      Assert
        (not Editor.Syntax_Cache.Line_Is_Cacheable
           (Cache, Editor.Syntax_Cache.Max_Cached_Lines + 1),
         "rows beyond the fixed cache budget must be reported as uncacheable");
      Assert
        (Editor.Syntax_Cache.Tokens_For_Line
           (Cache, Editor.Syntax_Cache.Max_Cached_Lines + 1)'Length = 0,
         "uncacheable rows must degrade to no cached tokens, never stale spans");
   end Test_Cache_Line_Cap_Degrades_Safely;

   procedure Test_Token_Cap_Reports_Overflow_Without_Spill
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Cache : Editor.Syntax_Cache.Syntax_Cache;
      Line  : Unbounded_String := Null_Unbounded_String;
      Changed : Boolean := False;
   begin
      for I in 1 .. Editor.Syntax_Cache.Max_Tokens_Per_Line + 20 loop
         Append (Line, "A" & Natural'Image (I) & " + ");
      end loop;

      Editor.Syntax_Cache.Set_Line_Count (Cache, 2);
      Editor.Syntax_Cache.Relex_Dirty_Line (Cache, 1, To_String (Line), Changed);

      Assert
        (Editor.Syntax_Cache.Tokens_For_Line (Cache, 1)'Length =
           Editor.Syntax_Cache.Max_Tokens_Per_Line,
         "overflow line must retain only the fixed token budget");
      Assert
        (Editor.Syntax_Cache.Token_Overflowed (Cache, 1),
         "overflow line must expose safe-degradation status");
      Assert
        (Editor.Syntax_Cache.Tokens_For_Line (Cache, 2)'Length = 0,
         "overflow on one line must not spill tokens into the next line");
   end Test_Token_Cap_Reports_Overflow_Without_Spill;

   procedure Test_Shrink_Then_Dirty_Extend_Does_Not_Reexpose_Stale_Lines
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Cache : Editor.Syntax_Cache.Syntax_Cache;
      Changed : Boolean := False;
   begin
      Editor.Syntax_Cache.Set_Line_Count (Cache, 3);
      Editor.Syntax_Cache.Relex_Dirty_Line
        (Cache, 1, "procedure Demo is", Changed);
      Editor.Syntax_Cache.Relex_Dirty_Line
        (Cache, 2, "begin", Changed);
      Editor.Syntax_Cache.Relex_Dirty_Line
        (Cache, 3, "   null;", Changed);

      Assert
        (Editor.Syntax_Cache.Tokens_For_Line (Cache, 3)'Length > 0,
         "setup must cache tokens on the later line");

      Editor.Syntax_Cache.Set_Line_Count (Cache, 1);
      Assert
        (Editor.Syntax_Cache.Tokens_For_Line (Cache, 3)'Length = 0,
         "shrinking the cache must hide dropped-line tokens immediately");

      Editor.Syntax_Cache.Mark_Line_Dirty (Cache, 3);
      Assert
        (Editor.Syntax_Cache.Tokens_For_Line (Cache, 3)'Length = 0,
         "dirty-extending after shrink must not re-expose stale dropped-line tokens");
      Assert
        (Editor.Syntax_Cache.Is_Dirty (Cache, 2),
         "dirty-extending after shrink must reset newly exposed intermediate lines");
      Assert
        (Editor.Syntax_Cache.Is_Dirty (Cache, 3),
         "dirty-extending after shrink must mark the requested line dirty");

      Editor.Syntax_Cache.Set_Line_Count (Cache, 1);
      Editor.Syntax_Cache.Mark_Range_Dirty (Cache, 2, 3);
      Assert
        (Editor.Syntax_Cache.Tokens_For_Line (Cache, 3)'Length = 0,
         "range dirty-extension after shrink must also avoid stale token reuse");
      Assert
        (Editor.Syntax_Cache.Is_Dirty (Cache, 2),
         "range dirty-extension must mark the first newly exposed line dirty");
      Assert
        (Editor.Syntax_Cache.Is_Dirty (Cache, 3),
         "range dirty-extension must mark the last newly exposed line dirty");
   end Test_Shrink_Then_Dirty_Extend_Does_Not_Reexpose_Stale_Lines;



   procedure Assert_Syntax_Prepared_For_Current_Buffer
     (S   : in out Editor.State.State_Type;
      Why : String)
   is
   begin
      Editor.State.Prepare_Syntax_For_Visible_Range (S, 0, 0, True);
      Assert
        (S.Syntax_Source_Revision = S.Buffer_Revision,
         Why & ": syntax source revision must match active buffer revision");
      Assert
        (S.Syntax_Source_Buffer_Token = S.Active_Buffer_Token,
         Why & ": syntax source owner must match active buffer token");
      Assert
        (S.Syntax_Symbols_Revision = S.Buffer_Revision,
         Why & ": semantic symbol revision must match active buffer revision");
      Assert
        (S.Syntax_Symbols_Buffer_Token = S.Active_Buffer_Token,
         Why & ": semantic symbol owner must match active buffer token");
      Assert
        (Editor.Syntax_Cache.Tokens_For_Line (S.Syntax_Cache, 1)'Length > 0,
         Why & ": first line must have rebuilt syntax spans");
   end Assert_Syntax_Prepared_For_Current_Buffer;

   procedure Prime_Syntax_State
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      Editor.State.Replace_Buffer_Contents (S, Text);
      S.Active_Buffer_Token := 101;
      Assert_Syntax_Prepared_For_Current_Buffer (S, "prime");
   end Prime_Syntax_State;

   procedure Assert_Post_Edit_Syntax_Invalidated
     (S                   : in out Editor.State.State_Type;
      Expected_Revision   : Natural;
      Why                 : String)
   is
   begin
      Assert
        (S.Buffer_Revision /= Expected_Revision,
         Why & ": edit path must advance buffer revision");
      Assert
        (S.Syntax_Source_Revision = S.Buffer_Revision,
         Why & ": edit path must restamp lexical revision to the changed buffer");
      Assert
        (S.Syntax_Source_Buffer_Token = S.Active_Buffer_Token,
         Why & ": edit path must keep lexical owner on active buffer");
      Assert
        (S.Syntax_Symbols_Revision = Natural'Last,
         Why & ": edit path must invalidate semantic symbols");
      Assert
        (S.Syntax_Symbols_Buffer_Token = 0,
         Why & ": edit path must clear semantic symbol owner until explicit rebuild");
      Assert
        (Editor.Syntax_Cache.Is_Dirty (S.Syntax_Cache, 1),
         Why & ": changed first row must be marked dirty for relexing");
      Assert_Syntax_Prepared_For_Current_Buffer (S, Why & " after prepare");
   end Assert_Post_Edit_Syntax_Invalidated;

   procedure Test_Syntax_Invalidation_Insert_Delete_Paste_Replace
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Natural;

      procedure Insert_Keyword (B : in out Text_Buffer.Buffer_Type) is
      begin
         Text_Buffer.Insert (B, 0, Ch => 'X');
      end Insert_Keyword;

      procedure Delete_Keyword (B : in out Text_Buffer.Buffer_Type) is
      begin
         Text_Buffer.Delete (B, 0);
      end Delete_Keyword;

      procedure Paste_Text (B : in out Text_Buffer.Buffer_Type) is
      begin
         Text_Buffer.Replace_Range (B, 0, 0, "with Ada.Text_IO;" & ASCII.LF);
      end Paste_Text;

      procedure Replace_Text (B : in out Text_Buffer.Buffer_Type) is
      begin
         Text_Buffer.Replace_Range (B, 0, 4, "package");
      end Replace_Text;
   begin
      Editor.State.Init (S);

      Prime_Syntax_State (S, "procedure Demo is begin null; end Demo;");
      Before := S.Buffer_Revision;
      Editor.State.Mutate_Buffer (S, Insert_Keyword'Access);
      Assert_Post_Edit_Syntax_Invalidated (S, Before, "insert invalidation");

      Before := S.Buffer_Revision;
      Editor.State.Mutate_Buffer (S, Delete_Keyword'Access);
      Assert_Post_Edit_Syntax_Invalidated (S, Before, "delete invalidation");

      Before := S.Buffer_Revision;
      Editor.State.Mutate_Buffer (S, Paste_Text'Access);
      Assert_Post_Edit_Syntax_Invalidated (S, Before, "paste invalidation");

      Before := S.Buffer_Revision;
      Editor.State.Mutate_Buffer (S, Replace_Text'Access);
      Assert_Post_Edit_Syntax_Invalidated (S, Before, "replace invalidation");
   end Test_Syntax_Invalidation_Insert_Delete_Paste_Replace;

   procedure Test_Syntax_Invalidation_Undo_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Before : Natural;
      Cmd    : Editor.Commands.Command;
   begin
      Editor.State.Init (S);
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;
      Prime_Syntax_State (S, "procedure Undo_Demo is begin null; end Undo_Demo;");

      Cmd := Editor.Test_Helper.Insert (0, '-');
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert_Syntax_Prepared_For_Current_Buffer (S, "post edit before undo");

      Before := S.Buffer_Revision;
      Cmd := Editor.Test_Helper.Undo;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert_Post_Edit_Syntax_Invalidated (S, Before, "undo invalidation");

      Before := S.Buffer_Revision;
      Cmd := Editor.Test_Helper.Redo;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert_Post_Edit_Syntax_Invalidated (S, Before, "redo invalidation");
   end Test_Syntax_Invalidation_Undo_Redo;

   procedure Assert_Whole_Document_Syntax_Reset
     (S                 : in out Editor.State.State_Type;
      Previous_Revision : Natural;
      Previous_Token    : Natural;
      Why               : String)
   is
   begin
      Assert
        (S.Buffer_Revision /= Previous_Revision,
         Why & ": whole-document lifecycle path must advance buffer revision");
      Assert
        (S.Syntax_Source_Revision = Natural'Last,
         Why & ": whole-document lifecycle path must clear lexical revision");
      Assert
        (S.Syntax_Source_Buffer_Token = 0,
         Why & ": whole-document lifecycle path must clear lexical owner");
      Assert
        (S.Syntax_Symbols_Revision = Natural'Last,
         Why & ": whole-document lifecycle path must clear semantic revision");
      Assert
        (S.Syntax_Symbols_Buffer_Token = 0,
         Why & ": whole-document lifecycle path must clear semantic owner");
      S.Active_Buffer_Token := Previous_Token;
      Assert_Syntax_Prepared_For_Current_Buffer (S, Why & " after prepare");
   end Assert_Whole_Document_Syntax_Reset;

   procedure Test_Syntax_Invalidation_Open_Reload_Revert_Workspace_Restore
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Natural;
      Token  : Natural;
   begin
      Editor.State.Init (S);
      Prime_Syntax_State (S, "procedure Original is begin null; end Original;");
      Token := S.Active_Buffer_Token;

      Before := S.Buffer_Revision;
      Editor.State.Replace_Buffer_Contents (S, "package Opened is end Opened;");
      Assert_Whole_Document_Syntax_Reset (S, Before, Token, "open buffer invalidation");

      Before := S.Buffer_Revision;
      Editor.State.Replace_Buffer_Contents (S, "procedure Reloaded is begin null; end Reloaded;");
      Assert_Whole_Document_Syntax_Reset (S, Before, Token, "reload invalidation");

      Before := S.Buffer_Revision;
      Editor.State.Replace_Buffer_Contents (S, "procedure Reverted is begin null; end Reverted;");
      Assert_Whole_Document_Syntax_Reset (S, Before, Token, "revert invalidation");

      Before := S.Buffer_Revision;
      Editor.State.Replace_Buffer_Contents (S, "package Restored.Workspace is end Restored.Workspace;");
      Assert_Whole_Document_Syntax_Reset (S, Before, Token, "workspace restore invalidation");
   end Test_Syntax_Invalidation_Open_Reload_Revert_Workspace_Restore;

   procedure Test_Syntax_Save_As_Does_Not_Persist_Stale_Runtime_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Revision : Natural;
      Before_Source_Revision : Natural;
      Before_Token : Natural;
   begin
      Editor.State.Init (S);
      Prime_Syntax_State (S, "procedure Save_As_Demo is begin null; end Save_As_Demo;");
      Before_Revision := S.Buffer_Revision;
      Before_Source_Revision := S.Syntax_Source_Revision;
      Before_Token := S.Syntax_Source_Buffer_Token;

      --  Save-as establishes a file identity/baseline without changing text.
      --  It must not silently persist detached syntax state or force a stale
      --  rebuild when the active buffer text/revision are unchanged.
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Editor.Test_Temp.Base & "/save-as-demo.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("save-as-demo.adb");
      S.File_Info.Dirty := False;
      Editor.State.Reset_Dirty_Line_Baseline (S);

      Assert
        (S.Buffer_Revision = Before_Revision,
         "save-as baseline update must not mutate buffer text revision");
      Assert
        (S.Syntax_Source_Revision = Before_Source_Revision,
         "save-as baseline update must not stale lexical cache for unchanged text");
      Assert
        (S.Syntax_Source_Buffer_Token = Before_Token,
         "save-as baseline update must keep syntax ownership on active buffer");
      Assert_Syntax_Prepared_For_Current_Buffer (S, "save-as unchanged text");
   end Test_Syntax_Save_As_Does_Not_Persist_Stale_Runtime_State;

   procedure Test_Syntax_Invalidation_External_Conflict_Resolution
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Before : Natural;
      Token  : Natural;

      procedure Apply_Disk_Text (B : in out Text_Buffer.Buffer_Type) is
      begin
         Text_Buffer.Set_Text (B, "procedure Disk_Copy is begin null; end Disk_Copy;");
      end Apply_Disk_Text;
   begin
      Editor.State.Init (S);
      Prime_Syntax_State (S, "procedure Buffer_Copy is begin null; end Buffer_Copy;");
      Token := S.Active_Buffer_Token;
      S.File_Info.External_Change_Surfaced := True;
      Before := S.Buffer_Revision;

      Editor.State.Mutate_Buffer (S, Apply_Disk_Text'Access);
      S.File_Info.External_Change_Surfaced := False;
      S.File_Info.Last_Reload_Failed := False;
      S.File_Info.Last_Revert_Failed := False;

      Assert_Post_Edit_Syntax_Invalidated (S, Before, "external conflict reload invalidation");
      Assert
        (S.Syntax_Source_Buffer_Token = Token,
         "external conflict reload must keep rebuilt syntax owned by active buffer");
   end Test_Syntax_Invalidation_External_Conflict_Resolution;

   function Line_Has_Kind
     (S           : Editor.State.State_Type;
      Line_Number : Positive;
      Kind        : Editor.Syntax.Token_Kind) return Boolean
   is
      Tokens : constant Editor.Syntax.Token_Span_Array :=
        Editor.Syntax_Cache.Tokens_For_Line (S.Syntax_Cache, Line_Number);
   begin
      for I in Tokens'Range loop
         if Tokens (I).Kind = Kind then
            return True;
         end if;
      end loop;
      return False;
   end Line_Has_Kind;

   procedure Test_Prepare_Backtracks_To_Earlier_Dirty_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;

      procedure Close_First_Line_String (B : in out Text_Buffer.Buffer_Type) is
      begin
         Text_Buffer.Set_Text
           (B, "S := ""open""" & ASCII.LF & "Y : Integer := 1;");
      end Close_First_Line_String;
   begin
      Editor.State.Init (S);
      Editor.State.Replace_Buffer_Contents
        (S, "S := ""open" & ASCII.LF & "Y : Integer := 1;");
      S.Active_Buffer_Token := 303;
      Editor.State.Prepare_Syntax_For_Visible_Range (S, 0, 1, True);
      Assert
        (Line_Has_Kind (S, 2, Editor.Syntax.String_Literal),
         "initial unterminated string should propagate to the following line");

      Editor.State.Mutate_Buffer (S, Close_First_Line_String'Access);
      Editor.State.Prepare_Syntax_For_Visible_Range (S, 1, 1, True);

      Assert
        (not Line_Has_Kind (S, 2, Editor.Syntax.String_Literal),
         "preparing a later visible row must relex earlier dirty lexical-state owners first");
      Assert
        (Line_Has_Kind (S, 2, Editor.Syntax.Identifier),
         "following line should recover to ordinary Ada tokens after predecessor state changes");
   end Test_Prepare_Backtracks_To_Earlier_Dirty_Line;

   procedure Test_Empty_Buffer_Clears_Syntax_Ownership
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Prime_Syntax_State (S, "procedure Nonempty is begin null; end Nonempty;");
      Editor.State.Replace_Buffer_Contents (S, "");
      S.Active_Buffer_Token := 404;
      Editor.State.Prepare_Syntax_For_Visible_Range (S, 0, 0, True);

      Assert
        (S.Syntax_Source_Revision = Natural'Last,
         "empty buffer must not retain a stale lexical source revision");
      Assert
        (S.Syntax_Source_Buffer_Token = 0,
         "empty buffer must not retain stale lexical owner token");
      Assert
        (S.Syntax_Symbols_Revision = Natural'Last,
         "empty buffer must not retain a stale semantic source revision");
      Assert
        (S.Syntax_Symbols_Buffer_Token = 0,
         "empty buffer must not retain stale semantic owner token");
      Assert
        (Editor.Syntax_Cache.Tokens_For_Line (S.Syntax_Cache, 1)'Length = 0,
         "empty buffer must expose no cached syntax spans");
   end Test_Empty_Buffer_Clears_Syntax_Ownership;


   procedure Test_Edit_At_Top_Invalidates_Shifted_Cached_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;

      procedure Insert_Header_Line (B : in out Text_Buffer.Buffer_Type) is
      begin
         Text_Buffer.Replace_Range (B, 0, 0, "-- inserted header" & ASCII.LF);
      end Insert_Header_Line;
   begin
      Editor.State.Init (S);
      Editor.State.Replace_Buffer_Contents
        (S,
         "procedure Shifted is" & ASCII.LF
         & "X : String := ""old"";" & ASCII.LF
         & "Y : Integer := 1;");
      S.Active_Buffer_Token := 505;
      Editor.State.Prepare_Syntax_For_Visible_Range (S, 0, 2, True);
      Assert
        (Line_Has_Kind (S, 2, Editor.Syntax.String_Literal),
         "initial second line should contain the cached string literal");
      Assert
        (not Line_Has_Kind (S, 3, Editor.Syntax.String_Literal),
         "initial third line should not contain the string literal");

      Editor.State.Mutate_Buffer (S, Insert_Header_Line'Access);
      Editor.State.Prepare_Syntax_For_Visible_Range (S, 2, 2, True);

      Assert
        (Line_Has_Kind (S, 3, Editor.Syntax.String_Literal),
         "editing above cached rows must invalidate shifted rows, not reuse stale line-3 tokens");
      Assert
        (Line_Has_Kind (S, 2, Editor.Syntax.Keyword),
         "the shifted procedure line should be relexed at its new row");
   end Test_Edit_At_Top_Invalidates_Shifted_Cached_Rows;


   procedure Test_Prepare_Semantics_Uses_Language_Model_Analysis
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Replace_Buffer_Contents
        (S,
         "type R is record" & ASCII.LF
         & "   Field : Integer;" & ASCII.LF
         & "end record;");
      S.Active_Buffer_Token := 606;

      Editor.State.Prepare_Syntax_For_Visible_Range (S, 0, 2, True);

      Assert
        (Editor.Syntax_Semantics.Kind_For_Identifier
           (S.Syntax_Symbols, "Field") = Editor.Syntax.Parameter_Identifier,
         "visible-range semantic preparation must use parser-owned language-model record components");
      Assert
        (S.Syntax_Symbols_Revision = S.Buffer_Revision,
         "language-model semantic map must be stamped with the current revision");
      Assert
        (S.Syntax_Symbols_Buffer_Token = S.Active_Buffer_Token,
         "language-model semantic map must be stamped with the active buffer token");
   end Test_Prepare_Semantics_Uses_Language_Model_Analysis;

   procedure Register_Tests (T : in out Syntax_Cache_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Incremental_State_Propagation'Access, "incremental lexical state propagation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Range_Dirty'Access, "range dirty marking");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Snapshot_Consumes_Syntax_Cache'Access,
         "render snapshot consumes cached syntax spans");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Active_Buffer_Token_Mismatch_Clears_Syntax_Owner'Access,
         "syntax cache clears when active buffer identity changes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Buffer_Switch_Does_Not_Reuse_Syntax_State'Access,
         "syntax cache is owned by active buffer identity");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Cache_Line_Cap_Degrades_Safely'Access,
         "line cap degrades safely");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Token_Cap_Reports_Overflow_Without_Spill'Access,
         "token cap reports overflow without spill");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Shrink_Then_Dirty_Extend_Does_Not_Reexpose_Stale_Lines'Access,
         "cache shrink then dirty-extend does not re-expose stale lines");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Syntax_Invalidation_Insert_Delete_Paste_Replace'Access,
         "syntax invalidation matrix: insert delete paste replace");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Syntax_Invalidation_Undo_Redo'Access,
         "syntax invalidation matrix: undo redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Syntax_Invalidation_Open_Reload_Revert_Workspace_Restore'Access,
         "syntax invalidation matrix: open reload revert workspace restore");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Syntax_Save_As_Does_Not_Persist_Stale_Runtime_State'Access,
         "syntax invalidation matrix: save-as baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Syntax_Invalidation_External_Conflict_Resolution'Access,
         "syntax invalidation matrix: external conflict resolution");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Prepare_Backtracks_To_Earlier_Dirty_Line'Access,
         "prepare backtracks to earlier dirty lexical-state owners");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Empty_Buffer_Clears_Syntax_Ownership'Access,
         "empty buffer clears syntax ownership stamps");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Edit_At_Top_Invalidates_Shifted_Cached_Rows'Access,
         "edit above cached rows invalidates shifted syntax rows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Prepare_Semantics_Uses_Language_Model_Analysis'Access,
         "visible-range semantics uses Ada language-model analysis");
   end Register_Tests;

end Editor.Syntax_Cache.Tests;
