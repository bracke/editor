with AUnit.Assertions; use AUnit.Assertions;
with Ada.Containers; use Ada.Containers;
with Editor.State;
with Editor.Cursors; use Editor.Cursors;
with Text_Buffer;
with Editor.Unicode;
with Editor.UTF8;

package body Buffer_Tests is

   ------------------------------------------------------------------------
   --  Helpers
   ------------------------------------------------------------------------

   procedure Insert_Character
     (B     : in out Text_Buffer.Buffer_Type;
      Index : Natural;
      Ch    : Character)
   is
   begin
      Text_Buffer.Insert (B, Index, Ch);
   end Insert_Character;

   procedure Insert_Text
     (B : in out Text_Buffer.Buffer_Type;
      S : String)
   is
   begin
      for I in S'Range loop
         Insert_Character
           (B,
            Text_Buffer.Length (B),
            S (I));
      end loop;
   end Insert_Text;

   procedure Assert_Text
     (B        : Text_Buffer.Buffer_Type;
      Expected : String;
      Message  : String)
   is
   begin
      Assert
        (Text_Buffer.Length (B) = Expected'Length,
         Message & ": length");

      for I in Expected'Range loop
         Assert
           (Text_Buffer.Element (B, I - Expected'First + 1) = Expected (I),
            Message & ": char" & Integer'Image (I - Expected'First + 1));
      end loop;
   end Assert_Text;

   function Buffer_To_String
   (B : Text_Buffer.Buffer_Type) return String
   is
      Result : String (1 .. Text_Buffer.Length (B));
   begin
      for I in Result'Range loop
         Result (I) := Text_Buffer.Element (B, I);
      end loop;

      return Result;
   end Buffer_To_String;

   procedure Assert_Line_Index_Matches_Buffer
   (S       : Editor.State.State_Type;
      Message : String)
   is
      Expected : Editor.State.Line_Start_Vectors.Vector;
      Pos      : Natural := 0;

      procedure Visit (Ch : Character) is
      begin
         if Ch = ASCII.LF then
            Expected.Append (Pos + 1);
         end if;

         Pos := Pos + 1;
      end Visit;
   begin
      Expected.Append (0);

      Text_Buffer.For_Each_Char
      (S.Buffer,
         Visit'Access);

      Assert
      (Editor.State.Line_Count (S) = Natural (Expected.Length),
         Message & ": line count");

      for I in Expected.First_Index .. Expected.Last_Index loop
         Assert
         (Natural (Editor.State.Line_Start (S, I)) = Expected.Element (I),
            Message & ": line start" & Natural'Image (I));
      end loop;
   end Assert_Line_Index_Matches_Buffer;

   procedure Assert_Caret_Invariants
   (S       : Editor.State.State_Type;
      Message : String)
   is
      Len : constant Cursor_Index :=
      Cursor_Index (Text_Buffer.Length (S.Buffer));
   begin
      Assert
      (S.Carets.Length > 0,
         Message & ": must have at least one caret");

      for I in S.Carets.First_Index .. S.Carets.Last_Index loop
         Assert
         (S.Carets (I).Pos <= Len,
            Message & ": caret pos out of bounds");

         Assert
         (S.Carets (I).Anchor <= Len,
            Message & ": caret anchor out of bounds");
      end loop;

      if S.Carets.Length > 1 then
         for I in S.Carets.First_Index .. S.Carets.Last_Index - 1 loop
            Assert
            (S.Carets (I).Pos <= S.Carets (I + 1).Pos,
               Message & ": carets must be sorted");
         end loop;
      end if;
   end Assert_Caret_Invariants;

   ------------------------------------------------------------------------
   --  Tests
   ------------------------------------------------------------------------

   procedure Test_Insert_At_Start
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Clear (B);

      Insert_Text (B, "bc");
      Insert_Character (B, 0, 'a');

      Assert_Text (B, "abc", "insert at start");
   end Test_Insert_At_Start;

   procedure Test_Insert_At_End
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Clear (B);

      Insert_Text (B, "ab");
      Insert_Character (B, Text_Buffer.Length (B), 'c');

      Assert_Text (B, "abc", "insert at end");
   end Test_Insert_At_End;

   procedure Test_Insert_At_Middle
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Clear (B);

      Insert_Text (B, "ac");
      Insert_Character (B, 1, 'b');

      Assert_Text (B, "abc", "insert at middle");
   end Test_Insert_At_Middle;

   procedure Test_Delete_At_Start
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Clear (B);

      Insert_Text (B, "abc");
      Text_Buffer.Delete (B, 0);

      Assert_Text (B, "bc", "delete at start");
   end Test_Delete_At_Start;

   procedure Test_Delete_At_End
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Clear (B);

      Insert_Text (B, "abc");
      Text_Buffer.Delete (B, 2);

      Assert_Text (B, "ab", "delete at end");
   end Test_Delete_At_End;

   procedure Test_Delete_At_Middle
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Clear (B);

      Insert_Text (B, "abc");
      Text_Buffer.Delete (B, 1);

      Assert_Text (B, "ac", "delete at middle");
   end Test_Delete_At_Middle;

   procedure Test_Newline_Preservation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Clear (B);

      Insert_Text (B, "a" & ASCII.LF & "b");

      Assert
        (Text_Buffer.Length (B) = 3,
         "newline preservation: length");

      Assert
        (Text_Buffer.Element (B, 1) = 'a',
         "newline preservation: first char");

      Assert
        (Text_Buffer.Element (B, 2) = ASCII.LF,
         "newline preservation: newline");

      Assert
        (Text_Buffer.Element (B, 3) = 'b',
         "newline preservation: last char");
   end Test_Newline_Preservation;

   procedure Test_Delete_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Clear (B);

      Insert_Text (B, "abcdef");
      Text_Buffer.Delete_Range (B, 2, 3);

      Assert_Text (B, "abf", "delete range");
   end Test_Delete_Range;

   procedure Test_Replace_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Clear (B);

      Insert_Text (B, "abcdef");
      Text_Buffer.Replace_Range (B, 2, 3, 'X');

      Assert_Text (B, "abXf", "replace range");
   end Test_Replace_Range;

   procedure Test_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Clear (B);

      Insert_Text (B, "abc");
      Text_Buffer.Clear (B);

      Assert
        (Text_Buffer.Length (B) = 0,
         "clear must reset length");

      Assert
        (Text_Buffer.Element (B, 1) = Character'Val (0),
         "clear must remove first element");
   end Test_Clear;

   procedure Test_Large_Insert
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Clear (B);

      for I in 1 .. 300 loop
         Insert_Character
           (B,
            Text_Buffer.Length (B),
            'x');
      end loop;

      Assert
        (Text_Buffer.Length (B) = 300,
         "large insert length");

      for I in 1 .. 300 loop
         Assert
           (Text_Buffer.Element (B, I) = 'x',
            "large insert char" & Natural'Image (I));
      end loop;
   end Test_Large_Insert;

   procedure Test_For_Each_Char_Order
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B      : Text_Buffer.Buffer_Type;
      Seen   : String (1 .. 5);
      Cursor : Natural := 0;

      procedure Visit (Ch : Character) is
      begin
         Cursor := Cursor + 1;
         Seen (Cursor) := Ch;
      end Visit;
   begin
      Text_Buffer.Clear (B);

      Insert_Text (B, "ab" & ASCII.LF & "cd");

      Text_Buffer.For_Each_Char (B, Visit'Access);

      Assert (Cursor = 5,
            "For_Each_Char must visit all characters");

      Assert (Seen = "ab" & ASCII.LF & "cd",
            "For_Each_Char must preserve order");
   end Test_For_Each_Char_Order;

   procedure Test_Repeated_Middle_Inserts
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Clear (B);

      Insert_Text (B, "aa");

      for I in 1 .. 20 loop
         Insert_Character (B, 1, 'x');
      end loop;

      Assert (Text_Buffer.Length (B) = 22,
            "Repeated middle inserts length");

      Assert (Text_Buffer.Element (B, 1) = 'a',
            "Repeated middle inserts first char");

      for I in 2 .. 21 loop
         Assert (Text_Buffer.Element (B, I) = 'x',
               "Repeated middle inserts x" & Natural'Image (I));
      end loop;

      Assert (Text_Buffer.Element (B, 22) = 'a',
            "Repeated middle inserts last char");
   end Test_Repeated_Middle_Inserts;

   procedure Test_Repeated_Middle_Deletes
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Clear (B);

      Insert_Text (B, "abcdefghijklmnop");

      for I in 1 .. 6 loop
         Text_Buffer.Delete (B, 5);
      end loop;

      Assert_Text
      (B,
         "abcde" & "lmnop",
         "Repeated middle deletes");
   end Test_Repeated_Middle_Deletes;

   procedure Test_Alternating_End_And_Middle_Edits
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Clear (B);

      Insert_Text (B, "mn");

      --  front / back / middle mutations
      Insert_Character (B, 0, 'a');                    --  amn
      Insert_Character (B, Text_Buffer.Length (B), 'z'); --  amnz
      Insert_Character (B, 2, 'X');                    --  amXnz
      Text_Buffer.Delete (B, 1);                         --  aXnz
      Insert_Character (B, 2, 'Y');                    --  aXYnz
      Text_Buffer.Delete (B, Text_Buffer.Length (B) - 1); --  aXYn
      Insert_Character (B, 0, '0');                    --  0aXYn

      Assert_Text
      (B,
         "0aXYn",
         "Alternating end and middle edits");
   end Test_Alternating_End_And_Middle_Edits;

   procedure Test_Leaf_Merge_Boundary
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Clear (B);

      for I in 1 .. 128 loop
         Insert_Character (B, Text_Buffer.Length (B), 'x');
      end loop;

      Assert (Text_Buffer.Length (B) = 128,
            "Leaf merge boundary length");

      for I in 1 .. 128 loop
         Assert (Text_Buffer.Element (B, I) = 'x',
               "Leaf merge boundary char" & Natural'Image (I));
      end loop;
   end Test_Leaf_Merge_Boundary;

   procedure Test_Right_Heavy_Insert_Stress
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Clear (B);

      for I in 1 .. 1_000 loop
         Insert_Character (B, Text_Buffer.Length (B), 'x');
      end loop;

      Assert
      (Text_Buffer.Length (B) = 1_000,
         "Right-heavy insert stress length");

      for I in 1 .. 1_000 loop
         Assert
         (Text_Buffer.Element (B, I) = 'x',
            "Right-heavy insert stress char" & Natural'Image (I));
      end loop;
   end Test_Right_Heavy_Insert_Stress;

   procedure Test_Mixed_Edit_Stress
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Clear (B);

      --  grow buffer
      for I in 1 .. 500 loop
         Insert_Character (B, Text_Buffer.Length (B), 'a');
      end loop;

      --  alternate inserts in middle
      for I in 1 .. 200 loop
         Insert_Character (B, Text_Buffer.Length (B) / 2, 'b');
      end loop;

      --  delete chunks from middle
      for I in 1 .. 100 loop
         Text_Buffer.Delete (B, Text_Buffer.Length (B) / 2);
      end loop;

      --  append again
      for I in 1 .. 300 loop
         Insert_Character (B, Text_Buffer.Length (B), 'c');
      end loop;

      --  basic invariants
      Assert
      (Text_Buffer.Length (B) > 0,
         "Mixed edit stress length");

      --  verify no corruption (full scan)
      for I in 1 .. Text_Buffer.Length (B) loop
         declare
            Ch : constant Character := Text_Buffer.Element (B, I);
         begin
            Assert
            (Ch = 'a' or else Ch = 'b' or else Ch = 'c',
               "Mixed edit stress invalid char");
         end;
      end loop;
   end Test_Mixed_Edit_Stress;

   procedure Test_Deterministic_Edit_Fuzz
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B : Text_Buffer.Buffer_Type;

      Model     : String (1 .. 512) := [others => ASCII.NUL];
      Model_Len : Natural := 0;

      Seed : Natural := 12345;

      function Next_Rand return Natural is
      begin
         Seed := (Seed * 75 + 74) mod 65_537;
         return Seed;
      end Next_Rand;

      procedure Model_Insert
      (Pos : Natural;
         Ch  : Character)
      is
      begin
         if Model_Len = Model'Length then
            return;
         end if;

         for I in reverse Pos + 1 .. Model_Len loop
            Model (I + 1) := Model (I);
         end loop;

         Model (Pos + 1) := Ch;
         Model_Len := Model_Len + 1;
      end Model_Insert;

      procedure Model_Delete
      (Pos : Natural)
      is
      begin
         if Model_Len = 0 then
            return;
         end if;

         for I in Pos + 1 .. Model_Len - 1 loop
            Model (I) := Model (I + 1);
         end loop;

         Model_Len := Model_Len - 1;
      end Model_Delete;

      function Model_String return String is
      begin
         if Model_Len = 0 then
            return "";
         else
            return Model (1 .. Model_Len);
         end if;
      end Model_String;

      Chars : constant String := "abc" & ASCII.LF;
   begin
      Text_Buffer.Clear (B);

      for Step in 1 .. 1_000 loop
         declare
            R  : constant Natural := Next_Rand;
            Op : constant Natural := R mod 3;
         begin
            if Op = 0 or else Text_Buffer.Length (B) = 0 then
               declare
                  Pos : constant Natural :=
                  (if Text_Buffer.Length (B) = 0
                     then 0
                     else Next_Rand mod (Text_Buffer.Length (B) + 1));

                  Ch : constant Character :=
                  Chars (Chars'First + Integer (Next_Rand mod Chars'Length));
               begin
                  Insert_Character (B, Pos, Ch);
                  Model_Insert (Pos, Ch);
               end;

            else
               declare
                  Pos : constant Natural :=
                  Next_Rand mod Text_Buffer.Length (B);
               begin
                  Text_Buffer.Delete (B, Pos);
                  Model_Delete (Pos);
               end;
            end if;

            Assert
            (Text_Buffer.Length (B) = Model_Len,
               "Fuzz length mismatch at step" & Natural'Image (Step));

            Assert
            (Buffer_To_String (B) = Model_String,
               "Fuzz contents mismatch at step" & Natural'Image (Step));
         end;
      end loop;
   end Test_Deterministic_Edit_Fuzz;

   procedure Test_Line_Index_Deterministic_Edit_Fuzz
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      S    : Editor.State.State_Type;
      Seed : Natural := 12345;

      function Next_Rand return Natural is
      begin
         Seed := (Seed * 75 + 74) mod 65_537;
         return Seed;
      end Next_Rand;

      Chars : constant String := "abc" & ASCII.LF;
   begin
      Editor.State.Init (S);

      for Step in 1 .. 1_000 loop
         declare
            R  : constant Natural := Next_Rand;
            Op : constant Natural := R mod 3;
         begin
            if Op = 0 or else Text_Buffer.Length (S.Buffer) = 0 then
               declare
                  Pos : constant Natural :=
                  (if Text_Buffer.Length (S.Buffer) = 0
                     then 0
                     else Next_Rand mod (Text_Buffer.Length (S.Buffer) + 1));

                  Ch : constant Character :=
                  Chars (Chars'First + Integer (Next_Rand mod Chars'Length));
               begin
                  Insert_Character (S.Buffer, Pos, Ch);

                  Editor.State.Rebuild_After_Buffer_Change
                  (S,
                     (Start_Index => Pos,
                     Old_Length  => 0,
                     New_Length  => 1));
               end;

            else
               declare
                  Pos : constant Natural :=
                  Next_Rand mod Text_Buffer.Length (S.Buffer);
               begin
                  Text_Buffer.Delete (S.Buffer, Pos);

                  Editor.State.Rebuild_After_Buffer_Change
                  (S,
                     (Start_Index => Pos,
                     Old_Length  => 1,
                     New_Length  => 0));
               end;
            end if;

            Assert_Line_Index_Matches_Buffer
            (S,
               "Line index fuzz step" & Natural'Image (Step));

            Assert_Caret_Invariants
            (S, "Caret invariant fuzz step" & Natural'Image (Step));
         end;
      end loop;
   end Test_Line_Index_Deterministic_Edit_Fuzz;



   procedure Test_Set_Text_And_Range_Iteration
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B      : Text_Buffer.Buffer_Type;
      Seen   : String (1 .. 7);
      Cursor : Natural := 0;

      procedure Visit (Ch : Character) is
      begin
         Cursor := Cursor + 1;
         Seen (Cursor) := Ch;
      end Visit;
   begin
      Text_Buffer.Set_Text (B, "0123456789abcdef");

      Text_Buffer.For_Each_Char_Range (B, 4, 11, Visit'Access);

      Assert (Cursor = 7, "range iteration must visit requested count only");
      Assert (Seen = "456789a", "range iteration contents");
      Assert (Text_Buffer.Validate (B), "range iteration leaves rope valid");
   end Test_Set_Text_And_Range_Iteration;

   procedure Test_Range_Iteration_Across_Many_Leaves
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B      : Text_Buffer.Buffer_Type;
      Text   : String (1 .. 10_000);
      Seen   : String (1 .. 32);
      Cursor : Natural := 0;

      procedure Visit (Ch : Character) is
      begin
         Cursor := Cursor + 1;
         Seen (Cursor) := Ch;
      end Visit;
   begin
      for I in Text'Range loop
         Text (I) := Character'Val (Character'Pos ('a') + ((I - 1) mod 26));
      end loop;

      Text_Buffer.Set_Text (B, Text);
      Text_Buffer.For_Each_Char_Range (B, 4_990, 5_022, Visit'Access);

      Assert (Cursor = 32, "multi-leaf range count");

      for I in Seen'Range loop
         Assert
           (Seen (I) = Text (4_990 + I),
            "multi-leaf range char" & Natural'Image (I));
      end loop;

      Assert (Text_Buffer.Validate (B), "multi-leaf range valid rope");
      Assert (Text_Buffer.Leaf_Count (B) > 1, "bulk load must create leaves");
   end Test_Range_Iteration_Across_Many_Leaves;

   procedure Test_Bulk_Load_Large_Edit_Near_End
   (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B    : Text_Buffer.Buffer_Type;
      Text : String (1 .. 100_000);
   begin
      for I in Text'Range loop
         Text (I) := (if I mod 80 = 0 then ASCII.LF else 'x');
      end loop;

      Text_Buffer.Set_Text (B, Text);

      Assert (Text_Buffer.Length (B) = Text'Length, "large set_text length");
      Assert (Text_Buffer.Element (B, 80) = ASCII.LF, "large set_text newline");
      Assert (Text_Buffer.Validate (B), "large set_text valid rope");
      Assert (Text_Buffer.Tree_Height (B) <= 64, "large set_text balanced height");

      Insert_Character (B, 50_000, 'M');
      Assert (Text_Buffer.Element (B, 50_001) = 'M', "large middle insert");

      Text_Buffer.Delete (B, 4_095);
      Assert (Text_Buffer.Length (B) = Text'Length, "large delete after insert length");
      Assert (Text_Buffer.Validate (B), "large edit valid rope");
   end Test_Bulk_Load_Large_Edit_Near_End;


   procedure Test_Repeated_Appends_Stay_Valid
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      B : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Clear (B);

      for I in 1 .. 20_000 loop
         Insert_Character
           (B,
            Text_Buffer.Length (B),
            Character'Val (Character'Pos ('a') + ((I - 1) mod 26)));
      end loop;

      Assert (Text_Buffer.Length (B) = 20_000, "append stress length");
      Assert (Text_Buffer.Element (B, 1) = 'a', "append stress first char");
      Assert (Text_Buffer.Element (B, 20_000) = 'f', "append stress last char");
      Assert (Text_Buffer.Validate (B), "append stress valid rope");
      Assert
        (Text_Buffer.Tree_Height (B) <= 64,
         "append stress must remain under rebalance height cap");
   end Test_Repeated_Appends_Stay_Valid;


   procedure Test_Rope_Line_APIs_Empty_And_Trailing_Newline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      B : Text_Buffer.Buffer_Type;
      Row : Natural := 99;
      Col : Natural := 99;
   begin
      Text_Buffer.Clear (B);
      Assert (Text_Buffer.Line_Count (B) = 1, "empty buffer has one logical line");
      Assert (Text_Buffer.Line_Start_Index (B, 0) = 0, "empty line start");
      Assert (Text_Buffer.Line_End_Index (B, 0) = 0, "empty line end");
      Assert (Text_Buffer.Row_For_Index (B, 0) = 0, "empty row for index");

      Text_Buffer.Set_Text (B, "aa" & ASCII.LF & "bbb" & ASCII.LF);
      Assert (Text_Buffer.Line_Count (B) = 3, "trailing newline creates final empty row");
      Assert (Text_Buffer.Line_Start_Index (B, 0) = 0, "row 0 start");
      Assert (Text_Buffer.Line_Start_Index (B, 1) = 3, "row 1 start");
      Assert (Text_Buffer.Line_Start_Index (B, 2) = 7, "row 2 start");
      Assert (Text_Buffer.Line_End_Index (B, 0) = 2, "row 0 end excludes LF");
      Assert (Text_Buffer.Line_End_Index (B, 1) = 6, "row 1 end excludes LF");
      Assert (Text_Buffer.Line_End_Index (B, 2) = 7, "final empty row end");

      Assert (Text_Buffer.Row_For_Index (B, 0) = 0, "index at start row");
      Assert (Text_Buffer.Row_For_Index (B, 2) = 0, "index at LF row");
      Assert (Text_Buffer.Row_For_Index (B, 3) = 1, "index after first LF row");
      Assert (Text_Buffer.Row_For_Index (B, Text_Buffer.Length (B)) = 2, "EOF row");

      Text_Buffer.Row_Col_For_Index (B, 5, Row, Col);
      Assert (Row = 1 and then Col = 2, "row/col lookup");
      Assert (Text_Buffer.Validate_Line_Counts (B), "line count validation");
   end Test_Rope_Line_APIs_Empty_And_Trailing_Newline;

   procedure Test_Rope_Line_APIs_Across_Leaf_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      B    : Text_Buffer.Buffer_Type;
      Text : String (1 .. 9_000) := (others => 'x');
   begin
      Text (4_096) := ASCII.LF;
      Text (4_097) := 'y';
      Text (8_192) := ASCII.LF;

      Text_Buffer.Set_Text (B, Text);

      Assert (Text_Buffer.Leaf_Count (B) > 1, "test must cross rope leaves");
      Assert (Text_Buffer.Line_Count (B) = 3, "line count across leaves");
      Assert (Text_Buffer.Line_Start_Index (B, 1) = 4_096, "line start at first boundary LF + 1");
      Assert (Text_Buffer.Line_Start_Index (B, 2) = 8_192, "line start at second boundary LF + 1");
      Assert (Text_Buffer.Row_For_Index (B, 4_095) = 0, "row before first boundary LF");
      Assert (Text_Buffer.Row_For_Index (B, 4_096) = 1, "row after first boundary LF");
      Assert (Text_Buffer.Line_End_Index (B, 0) = 4_095, "first row end excludes boundary LF");
      Assert (Text_Buffer.Validate_Line_Counts (B), "line count validation across leaves");
   end Test_Rope_Line_APIs_Across_Leaf_Boundaries;

   procedure Test_Rope_Line_APIs_Update_After_Newline_Edits
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      B : Text_Buffer.Buffer_Type;
   begin
      Text_Buffer.Set_Text (B, "abc");
      Assert (Text_Buffer.Line_Count (B) = 1, "initial single line");

      Insert_Character (B, 1, ASCII.LF);
      Assert (Text_Buffer.Line_Count (B) = 2, "insert newline updates line count");
      Assert (Text_Buffer.Line_Start_Index (B, 1) = 2, "insert newline updates start");
      Assert (Text_Buffer.Row_For_Index (B, 2) = 1, "insert newline updates row lookup");

      Text_Buffer.Delete (B, 1);
      Assert (Text_Buffer.Line_Count (B) = 1, "delete newline updates line count");
      Assert (Text_Buffer.Line_End_Index (B, 0) = Text_Buffer.Length (B), "delete newline updates end");
      Assert (Text_Buffer.Validate_Line_Counts (B), "line count validation after edits");
   end Test_Rope_Line_APIs_Update_After_Newline_Edits;

   ------------------------------------------------------------------------
   --  Registration
   ------------------------------------------------------------------------



   procedure Test_Unicode_UTF8_Buffer_Scalars
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      B       : Text_Buffer.Buffer_Type;
      E_Acute : constant Editor.Unicode.Code_Point :=
        Wide_Wide_Character'Val (16#00E9#);
      Smile   : constant Editor.Unicode.Code_Point :=
        Wide_Wide_Character'Val (16#1F642#);
      Seen    : Natural := 0;

      procedure Visit
        (Index : Natural;
         Code  : Editor.Unicode.Code_Point) is
      begin
         if Index = 0 then
            Assert (Code = Wide_Wide_Character'Val (Character'Pos ('A')),
                    "unicode visit ascii");
         elsif Index = 1 then
            Assert (Code = E_Acute, "unicode visit two-byte scalar");
         elsif Index = 2 then
            Assert (Code = Smile, "unicode visit four-byte scalar");
         end if;
         Seen := Seen + 1;
      end Visit;
   begin
      Text_Buffer.Clear (B);
      Insert_Character (B, 0, 'A');
      Text_Buffer.Insert (B, 1, E_Acute);
      Text_Buffer.Insert (B, 2, Smile);

      Assert (Text_Buffer.Length (B) = 3, "unicode scalar length");
      Assert (Text_Buffer.Code_Point_At (B, 1) = E_Acute,
              "code point lookup");
      Assert (Text_Buffer.UTF8_Text (B) =
              "A" & Editor.UTF8.Encode_UTF8 (E_Acute) &
              Editor.UTF8.Encode_UTF8 (Smile),
              "utf8 storage text");

      Text_Buffer.For_Each_Code_Point_Range (B, 0, 3, Visit'Access);
      Assert (Seen = 3, "unicode range iteration count");

      Text_Buffer.Delete (B, 1);
      Assert (Text_Buffer.Length (B) = 2, "unicode delete scalar length");
      Assert (Text_Buffer.Code_Point_At (B, 1) = Smile,
              "unicode delete removes exactly one scalar");
   end Test_Unicode_UTF8_Buffer_Scalars;

   procedure Test_UTF8_Decode_Encode_And_Invalid_Replacement
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      E_Acute : constant Editor.Unicode.Code_Point :=
        Wide_Wide_Character'Val (16#00E9#);
      Euro : constant Editor.Unicode.Code_Point :=
        Wide_Wide_Character'Val (16#20AC#);
      Smile : constant Editor.Unicode.Code_Point :=
        Wide_Wide_Character'Val (16#1F642#);
      Encoded : constant String :=
        "A" & Editor.UTF8.Encode_UTF8 (E_Acute)
            & Editor.UTF8.Encode_UTF8 (Euro)
            & Editor.UTF8.Encode_UTF8 (Smile);
      Seen : Natural := 0;

      procedure Visit (Code : Editor.Unicode.Code_Point) is
      begin
         case Seen is
            when 0 =>
               Assert (Code = Wide_Wide_Character'Val (Character'Pos ('A')),
                       "UTF-8 decoder must preserve ASCII");
            when 1 =>
               Assert (Code = E_Acute,
                       "UTF-8 decoder must decode two-byte scalar");
            when 2 =>
               Assert (Code = Euro,
                       "UTF-8 decoder must decode three-byte scalar");
            when 3 =>
               Assert (Code = Smile,
                       "UTF-8 decoder must decode four-byte scalar");
            when others =>
               Assert (False, "UTF-8 decoder visited too many scalars");
         end case;
         Seen := Seen + 1;
      end Visit;

      Invalid_Seen : Natural := 0;
      procedure Visit_Invalid (Code : Editor.Unicode.Code_Point) is
      begin
         Invalid_Seen := Invalid_Seen + 1;
         Assert (Code = Editor.Unicode.Replacement_Character,
                 "Invalid UTF-8 must be replaced deterministically");
      end Visit_Invalid;
   begin
      Editor.UTF8.Decode_UTF8 (Encoded, Visit'Access, Editor.UTF8.Reject);
      Assert (Seen = 4, "UTF-8 decoder scalar count");

      Editor.UTF8.Decode_UTF8
        (String'(1 => Character'Val (16#C0#)),
         Visit_Invalid'Access,
         Editor.UTF8.Replace);
      Assert (Invalid_Seen = 1, "Invalid UTF-8 replacement count");
   end Test_UTF8_Decode_Encode_And_Invalid_Replacement;


   procedure Test_UTF8_Code_Point_Index_To_Byte_Offset
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      E_Acute : constant Editor.Unicode.Code_Point :=
        Wide_Wide_Character'Val (16#00E9#);
      Smile : constant Editor.Unicode.Code_Point :=
        Wide_Wide_Character'Val (16#1F642#);
      Text : constant String :=
        "A" & Editor.UTF8.Encode_UTF8 (E_Acute)
            & Editor.UTF8.Encode_UTF8 (Smile)
            & "Z";
   begin
      Assert (Editor.UTF8.Byte_Offset_For_Code_Point_Index (Text, 0) = 0,
              "scalar index 0 starts at byte offset 0");
      Assert (Editor.UTF8.Byte_Offset_For_Code_Point_Index (Text, 1) = 1,
              "scalar index 1 starts after one ASCII byte");
      Assert (Editor.UTF8.Byte_Offset_For_Code_Point_Index (Text, 2) = 3,
              "scalar index 2 starts after one two-byte scalar");
      Assert (Editor.UTF8.Byte_Offset_For_Code_Point_Index (Text, 3) = 7,
              "scalar index 3 starts after one four-byte scalar");
      Assert (Editor.UTF8.Byte_Offset_For_Code_Point_Index (Text, 4) = Text'Length,
              "scalar index at end maps to final byte offset");
   end Test_UTF8_Code_Point_Index_To_Byte_Offset;

   procedure Test_Unicode_Delete_Does_Not_Split_UTF8
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      B : Text_Buffer.Buffer_Type;
      E_Acute : constant Editor.Unicode.Code_Point :=
        Wide_Wide_Character'Val (16#00E9#);
      Smile : constant Editor.Unicode.Code_Point :=
        Wide_Wide_Character'Val (16#1F642#);
   begin
      Text_Buffer.Set_Text
        (B,
         "A" & Editor.UTF8.Encode_UTF8 (E_Acute)
             & Editor.UTF8.Encode_UTF8 (Smile)
             & "Z");

      Text_Buffer.Delete_Range (B, 1, 2);

      Assert (Text_Buffer.Length (B) = 2,
              "delete range removes two Unicode scalars");
      Assert (Text_Buffer.UTF8_Text (B) = "AZ",
              "delete range must preserve surrounding UTF-8 bytes");
      Assert (Text_Buffer.Validate (B),
              "buffer remains valid after Unicode delete range");
   end Test_Unicode_Delete_Does_Not_Split_UTF8;

   procedure Test_Buffer_Set_Text_Normalizes_Invalid_UTF8
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      B : Text_Buffer.Buffer_Type;
      Replacement : constant String :=
        Editor.UTF8.Encode_UTF8 (Editor.Unicode.Replacement_Character);
   begin
      Text_Buffer.Set_Text
        (B, "A" & String'(1 => Character'Val (16#C0#)) & "B");

      Assert (Text_Buffer.Length (B) = 3,
              "Invalid UTF-8 replacement must count as one scalar");
      Assert (Text_Buffer.UTF8_Text (B) = "A" & Replacement & "B",
              "Invalid UTF-8 must be normalized in buffer storage");
   end Test_Buffer_Set_Text_Normalizes_Invalid_UTF8;

   overriding procedure Register_Tests
     (T : in out Text_Buffer_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Insert_At_Start'Access,
         "Insert At Start");

      Register_Routine
        (T, Test_Insert_At_End'Access,
         "Insert At End");

      Register_Routine
        (T, Test_Insert_At_Middle'Access,
         "Insert At Middle");

      Register_Routine
        (T, Test_Delete_At_Start'Access,
         "Delete At Start");

      Register_Routine
        (T, Test_Delete_At_End'Access,
         "Delete At End");

      Register_Routine
        (T, Test_Delete_At_Middle'Access,
         "Delete At Middle");

      Register_Routine
        (T, Test_Newline_Preservation'Access,
         "Newline Preservation");

      Register_Routine
        (T, Test_Delete_Range'Access,
         "Delete Source_Span");

      Register_Routine
        (T, Test_Replace_Range'Access,
         "Replace Source_Span");

      Register_Routine
        (T, Test_Clear'Access,
         "Clear");

      Register_Routine
        (T, Test_Large_Insert'Access,
         "Large Insert");

      Register_Routine
        (T, Test_For_Each_Char_Order'Access,
         "For Each Char Order");

      Register_Routine
        (T, Test_Repeated_Middle_Inserts'Access,
         "Repeated Middle Inserts");

      Register_Routine
        (T, Test_Repeated_Middle_Deletes'Access,
         "Repeated Middle Deletes");

      Register_Routine
        (T, Test_Alternating_End_And_Middle_Edits'Access,
          "Alternating End And Middle Edits");

      Register_Routine
        (T, Test_Leaf_Merge_Boundary'Access,
          "Leaf Merge Boundary");

      Register_Routine
        (T, Test_Right_Heavy_Insert_Stress'Access,
          "Right Heavy Insert Stress");

      Register_Routine
        (T, Test_Mixed_Edit_Stress'Access,
          "Mixed Edit Stress");

      Register_Routine
        (T, Test_Deterministic_Edit_Fuzz'Access,
          "Deterministic Edit Fuzz");

      Register_Routine
        (T, Test_Line_Index_Deterministic_Edit_Fuzz'Access,
          "Line Index Deterministic Edit Fuzz");

      Register_Routine
        (T, Test_Set_Text_And_Range_Iteration'Access,
          "Set Text And Source_Span Iteration");

      Register_Routine
        (T, Test_Range_Iteration_Across_Many_Leaves'Access,
          "Source_Span Iteration Across Many Leaves");

      Register_Routine
        (T, Test_Bulk_Load_Large_Edit_Near_End'Access,
          "Bulk Load Large Edit Near End");

      Register_Routine
        (T, Test_Repeated_Appends_Stay_Valid'Access,
          "Repeated Appends Stay Valid");

      Register_Routine
        (T, Test_Rope_Line_APIs_Empty_And_Trailing_Newline'Access,
          "Rope Line APIs Empty And Trailing Newline");

      Register_Routine
        (T, Test_Rope_Line_APIs_Across_Leaf_Boundaries'Access,
          "Rope Line APIs Across Leaf Boundaries");

      Register_Routine
        (T, Test_Rope_Line_APIs_Update_After_Newline_Edits'Access,
          "Rope Line APIs Update After Newline Edits");


      Register_Routine
        (T, Test_Unicode_UTF8_Buffer_Scalars'Access,
          "Unicode UTF8 Buffer Scalars");

      Register_Routine
        (T, Test_UTF8_Decode_Encode_And_Invalid_Replacement'Access,
          "UTF8 Decode Encode And Invalid Replacement");

      Register_Routine
        (T, Test_Buffer_Set_Text_Normalizes_Invalid_UTF8'Access,
          "Buffer Set Text Normalizes Invalid UTF8");

      Register_Routine
        (T, Test_UTF8_Code_Point_Index_To_Byte_Offset'Access,
          "UTF8 Code Point Index To Byte Offset");

      Register_Routine
        (T, Test_Unicode_Delete_Does_Not_Split_UTF8'Access,
          "Unicode Delete Does Not Split UTF8");
   end Register_Tests;

   overriding function Name
     (T : Text_Buffer_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Text_Buffer");
   end Name;

end Buffer_Tests;