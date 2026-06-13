with Ada.Unchecked_Deallocation;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.UTF8;
with Editor.Unicode;

package body Text_Backend.Rope_Impl is

   procedure Free_Node is new Ada.Unchecked_Deallocation
     (Object => Rope_Node,
      Name   => Rope_Node_Access);

   ------------------------------------------------------------------------
   --  Basic node helpers
   ------------------------------------------------------------------------

   function Count_Line_Breaks (S : String) return Natural is
      Count : Natural := 0;
   begin
      for Ch of S loop
         if Ch = ASCII.LF then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Count_Line_Breaks;

   function Node_Length (N : Rope_Node_Access) return Natural is
   begin
      if N = null then
         return 0;
      else
         return N.Length;
      end if;
   end Node_Length;

   function Node_Line_Breaks (N : Rope_Node_Access) return Natural is
   begin
      if N = null then
         return 0;
      else
         return N.Line_Breaks;
      end if;
   end Node_Line_Breaks;

   function Make_Leaf (S : String) return Rope_Node_Access is
   begin
      if S'Length = 0 then
         return null;
      end if;

      return new Rope_Node'
        (Kind        => Leaf_Node,
         Length      => S'Length,
         Line_Breaks => Count_Line_Breaks (S),
         Text        => To_Unbounded_String (S));
   end Make_Leaf;

   function Make_Branch
     (Left  : Rope_Node_Access;
      Right : Rope_Node_Access) return Rope_Node_Access
   is
   begin
      if Left = null then
         return Right;
      elsif Right = null then
         return Left;
      else
         return new Rope_Node'
           (Kind        => Branch_Node,
            Length      => Node_Length (Left) + Node_Length (Right),
            Line_Breaks => Node_Line_Breaks (Left) + Node_Line_Breaks (Right),
            Left        => Left,
            Right       => Right,
            Weight      => Node_Length (Left));
      end if;
   end Make_Branch;

   procedure Free_Tree (N : in out Rope_Node_Access) is
   begin
      if N = null then
         return;
      end if;

      case N.Kind is
         when Leaf_Node =>
            null;

         when Branch_Node =>
            Free_Tree (N.Left);
            Free_Tree (N.Right);
      end case;

      Free_Node (N);
   end Free_Tree;

   function Clone (N : Rope_Node_Access) return Rope_Node_Access is
   begin
      if N = null then
         return null;
      end if;

      case N.Kind is
         when Leaf_Node =>
            return new Rope_Node'
              (Kind        => Leaf_Node,
               Length      => N.Length,
               Line_Breaks => N.Line_Breaks,
               Text        => N.Text);

         when Branch_Node =>
            return Make_Branch (Clone (N.Left), Clone (N.Right));
      end case;
   end Clone;

   function Is_UTF8_Continuation_Byte (Ch : Character) return Boolean is
      B : constant Natural := Character'Pos (Ch);
   begin
      return B in 16#80# .. 16#BF#;
   end Is_UTF8_Continuation_Byte;

   function Safe_UTF8_Split_Point (S : String) return Natural is
      Mid : Natural := S'First + (S'Length / 2) - 1;
   begin
      --  Set_Text normalizes storage to valid UTF-8 before building the rope.
      --  Keep leaf boundaries aligned to code-point starts anyway, so future
      --  leaf-local scans cannot inherit a partial UTF-8 sequence.
      while Mid > S'First
        and then Mid < S'Last
        and then Is_UTF8_Continuation_Byte (S (Mid + 1))
      loop
         Mid := Mid - 1;
      end loop;

      if Mid < S'First or else Mid >= S'Last then
         return S'First + (S'Length / 2) - 1;
      else
         return Mid;
      end if;
   end Safe_UTF8_Split_Point;

   function Build_Balanced (S : String) return Rope_Node_Access is
      Mid : Natural;
   begin
      if S'Length = 0 then
         return null;
      elsif S'Length <= Max_Leaf_Size then
         return Make_Leaf (S);
      else
         Mid := Safe_UTF8_Split_Point (S);
         return Make_Branch
           (Build_Balanced (S (S'First .. Mid)),
            Build_Balanced (S (Mid + 1 .. S'Last)));
      end if;
   end Build_Balanced;

   function Repeated_String (Ch : Character; Count : Natural) return String is
      Result : String (1 .. Count);
   begin
      for I in Result'Range loop
         Result (I) := Ch;
      end loop;

      return Result;
   end Repeated_String;

   ------------------------------------------------------------------------
   --  Traversal and lookup
   ------------------------------------------------------------------------

   procedure Traverse
     (N  : Rope_Node_Access;
      Fn : not null access procedure (Ch : Character))
   is
   begin
      if N = null then
         return;
      end if;

      case N.Kind is
         when Leaf_Node =>
            declare
               S : constant String := To_String (N.Text);
            begin
               for I in S'Range loop
                  Fn (S (I));
               end loop;
            end;

         when Branch_Node =>
            Traverse (N.Left, Fn);
            Traverse (N.Right, Fn);
      end case;
   end Traverse;

   procedure Traverse_Range
     (N      : Rope_Node_Access;
      Offset : Natural;
      Start  : Natural;
      Stop   : Natural;
      Fn     : not null access procedure (Ch : Character))
   is
      Left_Len : Natural := 0;
   begin
      if N = null or else Start >= Stop then
         return;
      end if;

      if Stop <= Offset or else Start >= Offset + N.Length then
         return;
      end if;

      case N.Kind is
         when Leaf_Node =>
            declare
               S    : constant String := To_String (N.Text);
               From : constant Natural :=
                 (if Start > Offset then Start - Offset else 0);
               To   : constant Natural :=
                 Natural'Min (N.Length, Stop - Offset);
            begin
               if From >= To then
                  return;
               end if;

               for I in From .. To - 1 loop
                  Fn (S (S'First + I));
               end loop;
            end;

         when Branch_Node =>
            Left_Len := Node_Length (N.Left);

            if Start < Offset + Left_Len then
               Traverse_Range (N.Left, Offset, Start, Stop, Fn);
            end if;

            if Stop > Offset + Left_Len then
               Traverse_Range
                 (N.Right, Offset + Left_Len, Start, Stop, Fn);
            end if;
      end case;
   end Traverse_Range;


   function Count_Line_Breaks_Before
     (N     : Rope_Node_Access;
      Index : Natural) return Natural
   is
      Pos   : Natural := Natural'Min (Index, Node_Length (N));
      Count : Natural := 0;
      Cur   : Rope_Node_Access := N;
   begin
      while Cur /= null loop
         case Cur.Kind is
            when Leaf_Node =>
               declare
                  S  : constant String := To_String (Cur.Text);
                  To : constant Natural := Natural'Min (Pos, Cur.Length);
               begin
                  if To > 0 then
                     for I in 0 .. To - 1 loop
                        if S (S'First + I) = ASCII.LF then
                           Count := Count + 1;
                        end if;
                     end loop;
                  end if;
               end;
               return Count;

            when Branch_Node =>
               if Pos < Cur.Weight then
                  Cur := Cur.Left;
               else
                  Count := Count + Node_Line_Breaks (Cur.Left);
                  Pos := Pos - Cur.Weight;
                  Cur := Cur.Right;
               end if;
         end case;
      end loop;

      return Count;
   end Count_Line_Breaks_Before;

   function Index_After_Nth_Line_Break
     (N      : Rope_Node_Access;
      Target : Positive) return Natural
   is
      Remaining : Natural := Target;
      Offset    : Natural := 0;
      Cur       : Rope_Node_Access := N;
   begin
      while Cur /= null loop
         case Cur.Kind is
            when Leaf_Node =>
               declare
                  S : constant String := To_String (Cur.Text);
               begin
                  for I in S'Range loop
                     if S (I) = ASCII.LF then
                        Remaining := Remaining - 1;
                        if Remaining = 0 then
                           return Offset + Natural (I - S'First) + 1;
                        end if;
                     end if;
                  end loop;
               end;
               return Node_Length (N);

            when Branch_Node =>
               declare
                  Left_Breaks : constant Natural := Node_Line_Breaks (Cur.Left);
               begin
                  if Remaining <= Left_Breaks then
                     Cur := Cur.Left;
                  else
                     Remaining := Remaining - Left_Breaks;
                     Offset := Offset + Node_Length (Cur.Left);
                     Cur := Cur.Right;
                  end if;
               end;
         end case;
      end loop;

      return Node_Length (N);
   end Index_After_Nth_Line_Break;

   function Char_At
     (N     : Rope_Node_Access;
      Index : Natural) return Character
   is
      S : constant String := (if N /= null and then N.Kind = Leaf_Node
                              then To_String (N.Text)
                              else "");
   begin
      if N = null or else Index >= N.Length then
         return Character'Val (0);
      end if;

      case N.Kind is
         when Leaf_Node =>
            return S (S'First + Index);

         when Branch_Node =>
            if Index < N.Weight then
               return Char_At (N.Left, Index);
            else
               return Char_At (N.Right, Index - N.Weight);
            end if;
      end case;
   end Char_At;

   ------------------------------------------------------------------------
   --  Destructive split / concat. These routines transfer ownership of input
   --  nodes to their result nodes. They do not clone full subtrees during edits.
   ------------------------------------------------------------------------

   function Concat
     (Left  : Rope_Node_Access;
      Right : Rope_Node_Access) return Rope_Node_Access;

   procedure Split
     (N     : in out Rope_Node_Access;
      Index : Natural;
      Left  : out Rope_Node_Access;
      Right : out Rope_Node_Access)
   is
   begin
      Left  := null;
      Right := null;

      if N = null then
         return;
      end if;

      if Index = 0 then
         Right := N;
         N := null;
         return;
      elsif Index >= N.Length then
         Left := N;
         N := null;
         return;
      end if;

      case N.Kind is
         when Leaf_Node =>
            declare
               S : constant String := To_String (N.Text);
            begin
               Left  := Make_Leaf (S (S'First .. S'First + Index - 1));
               Right := Make_Leaf (S (S'First + Index .. S'Last));
               Free_Node (N);
               N := null;
            end;

         when Branch_Node =>
            declare
               Old_Left  : Rope_Node_Access := N.Left;
               Old_Right : Rope_Node_Access := N.Right;
               Left_Len  : constant Natural := N.Weight;
               L1        : Rope_Node_Access;
               L2        : Rope_Node_Access;
               R1        : Rope_Node_Access;
               R2        : Rope_Node_Access;
            begin
               N.Left  := null;
               N.Right := null;
               Free_Node (N);

               if Index < Left_Len then
                  Split (Old_Left, Index, L1, L2);
                  Left  := L1;
                  Right := Concat (L2, Old_Right);

               elsif Index = Left_Len then
                  Left  := Old_Left;
                  Right := Old_Right;

               else
                  Split (Old_Right, Index - Left_Len, R1, R2);
                  Left  := Concat (Old_Left, R1);
                  Right := R2;
               end if;
            end;
      end case;
   end Split;

   function Concat
     (Left  : Rope_Node_Access;
      Right : Rope_Node_Access) return Rope_Node_Access
   is
   begin
      if Left = null then
         return Right;
      elsif Right = null then
         return Left;
      end if;

      if Left.Kind = Leaf_Node
        and then Right.Kind = Leaf_Node
        and then Left.Length + Right.Length <= Max_Leaf_Size
      then
         declare
            Merged : Rope_Node_Access :=
              Make_Leaf (To_String (Left.Text) & To_String (Right.Text));
            L      : Rope_Node_Access := Left;
            R      : Rope_Node_Access := Right;
         begin
            Free_Tree (L);
            Free_Tree (R);
            return Merged;
         end;
      elsif Left.Kind = Branch_Node and then Right.Kind = Leaf_Node then
         --  Common append path: absorb a small right leaf into the existing
         --  rightmost leaf when possible instead of adding one branch level
         --  per appended character. Ownership of Left's children is moved
         --  into the returned branch before the old branch shell is freed.
         declare
            Old_Left  : Rope_Node_Access := Left.Left;
            Old_Right : Rope_Node_Access := Left.Right;
            Shell     : Rope_Node_Access := Left;
            New_Right : Rope_Node_Access;
         begin
            Shell.Left  := null;
            Shell.Right := null;
            Free_Node (Shell);

            New_Right := Concat (Old_Right, Right);
            return Make_Branch (Old_Left, New_Right);
         end;
      elsif Left.Kind = Leaf_Node and then Right.Kind = Branch_Node then
         --  Symmetric prepend path used by inserts at the beginning.
         declare
            Old_Left  : Rope_Node_Access := Right.Left;
            Old_Right : Rope_Node_Access := Right.Right;
            Shell     : Rope_Node_Access := Right;
            New_Left  : Rope_Node_Access;
         begin
            Shell.Left  := null;
            Shell.Right := null;
            Free_Node (Shell);

            New_Left := Concat (Left, Old_Left);
            return Make_Branch (New_Left, Old_Right);
         end;
      end if;

      return Make_Branch (Left, Right);
   end Concat;

   ------------------------------------------------------------------------
   --  Shape validation and conservative rebalancing
   ------------------------------------------------------------------------

   function Node_Height (N : Rope_Node_Access) return Natural is
   begin
      if N = null then
         return 0;
      elsif N.Kind = Leaf_Node then
         return 1;
      else
         return 1 + Natural'Max (Node_Height (N.Left), Node_Height (N.Right));
      end if;
   end Node_Height;

   function Node_Leaf_Count (N : Rope_Node_Access) return Natural is
   begin
      if N = null then
         return 0;
      elsif N.Kind = Leaf_Node then
         return 1;
      else
         return Node_Leaf_Count (N.Left) + Node_Leaf_Count (N.Right);
      end if;
   end Node_Leaf_Count;

   procedure Append_Node_Text
     (N      : Rope_Node_Access;
      Result : in out Unbounded_String)
   is
   begin
      if N = null then
         return;
      end if;

      case N.Kind is
         when Leaf_Node =>
            Append (Result, N.Text);

         when Branch_Node =>
            Append_Node_Text (N.Left, Result);
            Append_Node_Text (N.Right, Result);
      end case;
   end Append_Node_Text;

   procedure Rebalance_If_Needed (B : in out Buffer_Type) is
   begin
      if Node_Height (B.Root) > Max_Allowed_Height then
         declare
            Flat : Unbounded_String;
            Old  : Rope_Node_Access := B.Root;
         begin
            Append_Node_Text (B.Root, Flat);
            B.Root := Build_Balanced (To_String (Flat));
            Free_Tree (Old);
         end;
      end if;
   end Rebalance_If_Needed;

   function Validate_Node
     (N           : Rope_Node_Access;
      Seen_Length : out Natural;
      Seen_Lines  : out Natural) return Boolean
   is
      Left_Length  : Natural := 0;
      Right_Length : Natural := 0;
      Left_Lines   : Natural := 0;
      Right_Lines  : Natural := 0;
   begin
      Seen_Length := 0;
      Seen_Lines  := 0;

      if N = null then
         return True;
      end if;

      case N.Kind is
         when Leaf_Node =>
            declare
               S : constant String := To_String (N.Text);
            begin
               Seen_Length := S'Length;
               Seen_Lines  := Count_Line_Breaks (S);
               return N.Length = Seen_Length
                 and then N.Line_Breaks = Seen_Lines
                 and then N.Length <= Max_Leaf_Size;
            end;

         when Branch_Node =>
            if not Validate_Node (N.Left, Left_Length, Left_Lines)
              or else not Validate_Node (N.Right, Right_Length, Right_Lines)
            then
               return False;
            end if;

            Seen_Length := Left_Length + Right_Length;
            Seen_Lines  := Left_Lines + Right_Lines;

            return N.Weight = Left_Length
              and then N.Length = Seen_Length
              and then N.Line_Breaks = Seen_Lines;
      end case;
   end Validate_Node;

   function Flat_Text (B : Buffer_Type) return String is
      Flat : Unbounded_String;
   begin
      Append_Node_Text (B.Root, Flat);
      return To_String (Flat);
   end Flat_Text;

   function UTF8_Code_Point_Count (Text : String) return Natural is
   begin
      return Editor.UTF8.Code_Point_Count (Text, Editor.UTF8.Replace);
   end UTF8_Code_Point_Count;

   function Byte_Offset (Text : String; Scalar_Index : Natural) return Natural is
   begin
      return Editor.UTF8.Byte_Offset_For_Code_Point_Index (Text, Scalar_Index);
   end Byte_Offset;

   function Normalize_UTF8 (Text : String) return String is
      Result : Unbounded_String := Null_Unbounded_String;
      procedure Visit (Code : Editor.Unicode.Code_Point) is
      begin
         Append (Result, Editor.UTF8.Encode_UTF8 (Code));
      end Visit;
   begin
      Editor.UTF8.Decode_UTF8 (Text, Visit'Access, Editor.UTF8.Replace);
      return To_String (Result);
   end Normalize_UTF8;

   procedure Rebuild_From_UTF8 (B : in out Buffer_Type; Text : String) is
      Safe_Text : constant String := Normalize_UTF8 (Text);
   begin
      Free_Tree (B.Root);
      B.Root := Build_Balanced (Safe_Text);
      B.Last := UTF8_Code_Point_Count (Safe_Text);
      B.Line_Breaks := Count_Line_Breaks (Safe_Text);
   end Rebuild_From_UTF8;

   procedure Refresh_Buffer_Counts (B : in out Buffer_Type) is
      Flat : constant String := Flat_Text (B);
   begin
      B.Last        := UTF8_Code_Point_Count (Flat);
      B.Line_Breaks := Count_Line_Breaks (Flat);
   end Refresh_Buffer_Counts;

   ------------------------------------------------------------------------
   --  Controlled operations
   ------------------------------------------------------------------------

   overriding procedure Adjust (B : in out Buffer_Type) is
   begin
      B.Root := Clone (B.Root);
   end Adjust;

   overriding procedure Finalize (B : in out Buffer_Type) is
   begin
      Free_Tree (B.Root);
      B.Last := 0;
      B.Line_Breaks := 0;
   end Finalize;

   ------------------------------------------------------------------------
   --  Public API
   ------------------------------------------------------------------------

   procedure Clear (B : in out Buffer_Type) is
   begin
      Free_Tree (B.Root);
      B.Last := 0;
      B.Line_Breaks := 0;
   end Clear;

   procedure Set_Text
     (B    : in out Buffer_Type;
      Text : String) is
   begin
      Rebuild_From_UTF8 (B, Text);
   end Set_Text;

   procedure Insert
     (B     : in out Buffer_Type;
      Index : Natural;
      Ch    : Character)
   is
   begin
      Insert (B, Index, Editor.Unicode.Code_Point'Val (Character'Pos (Ch)));
   end Insert;

   procedure Insert
     (B     : in out Buffer_Type;
      Index : Natural;
      Code  : Editor.Unicode.Code_Point)
   is
      Text : constant String := Flat_Text (B);
      Pos  : constant Natural := Byte_Offset (Text, Natural'Min (Index, B.Last));
      Enc  : constant String := Editor.UTF8.Encode_UTF8 (Code);
   begin
      if Text'Length = 0 then
         Rebuild_From_UTF8 (B, Enc);
      elsif Pos = 0 then
         Rebuild_From_UTF8 (B, Enc & Text);
      elsif Pos >= Text'Length then
         Rebuild_From_UTF8 (B, Text & Enc);
      else
         Rebuild_From_UTF8
           (B,
            Text (Text'First .. Text'First + Pos - 1) & Enc &
            Text (Text'First + Pos .. Text'Last));
      end if;
   end Insert;

   procedure Insert_Range
     (B     : in out Buffer_Type;
      Index : Natural;
      Ch    : Character;
      Count : Natural)
   is
      Text  : constant String := Flat_Text (B);
      Pos   : constant Natural := Byte_Offset (Text, Natural'Min (Index, B.Last));
      Chunk : constant String := Repeated_String (Ch, Count);
   begin
      if Count = 0 then
         return;
      elsif Text'Length = 0 then
         Rebuild_From_UTF8 (B, Chunk);
      elsif Pos = 0 then
         Rebuild_From_UTF8 (B, Chunk & Text);
      elsif Pos >= Text'Length then
         Rebuild_From_UTF8 (B, Text & Chunk);
      else
         Rebuild_From_UTF8
           (B,
            Text (Text'First .. Text'First + Pos - 1) & Chunk &
            Text (Text'First + Pos .. Text'Last));
      end if;
   end Insert_Range;

   procedure Delete
     (B     : in out Buffer_Type;
      Index : Natural)
   is
   begin
      if B.Last = 0 then
         return;
      end if;

      Delete_Range
        (B,
         (if Index >= B.Last then B.Last - 1 else Index),
         1);
   end Delete;

   procedure Delete_Range
     (B     : in out Buffer_Type;
      Start : Natural;
      Span  : Natural)
   is
      Text       : constant String := Flat_Text (B);
      Safe_Start : constant Natural := Natural'Min (Start, B.Last);
      Safe_Stop  : constant Natural := Natural'Min (Safe_Start + Span, B.Last);
      From_Byte  : constant Natural := Byte_Offset (Text, Safe_Start);
      To_Byte    : constant Natural := Byte_Offset (Text, Safe_Stop);
      Result     : Unbounded_String := Null_Unbounded_String;
   begin
      if Span = 0 or else B.Last = 0 or else Start >= B.Last then
         return;
      end if;

      if From_Byte > 0 then
         Append (Result, Text (Text'First .. Text'First + From_Byte - 1));
      end if;
      if To_Byte < Text'Length then
         Append (Result, Text (Text'First + To_Byte .. Text'Last));
      end if;
      Rebuild_From_UTF8 (B, To_String (Result));
   end Delete_Range;

   procedure Replace_Range
     (B     : in out Buffer_Type;
      Start : Natural;
      Span  : Natural;
      Ch    : Character) is
   begin
      Delete_Range (B, Start, Span);
      Insert (B, Start, Ch);
   end Replace_Range;

   procedure Replace_Range
     (B           : in out Buffer_Type;
      First       : Natural;
      Last        : Natural;
      Replacement : String)
   is
      Text       : constant String := Flat_Text (B);
      Start      : constant Natural := Natural'Min (First, B.Last);
      Stop       : constant Natural := Natural'Min (Last, B.Last);
      From_Byte  : constant Natural := Byte_Offset (Text, Start);
      To_Byte    : constant Natural := Byte_Offset (Text, Stop);
      Result     : Unbounded_String := Null_Unbounded_String;
   begin
      if Stop < Start then
         return;
      end if;

      if From_Byte > 0 then
         Append (Result, Text (Text'First .. Text'First + From_Byte - 1));
      end if;
      Append (Result, Replacement);
      if To_Byte < Text'Length then
         Append (Result, Text (Text'First + To_Byte .. Text'Last));
      end if;
      Rebuild_From_UTF8 (B, To_String (Result));
   end Replace_Range;

   function Length (B : Buffer_Type) return Natural is
   begin
      return B.Last;
   end Length;


   function Line_Count (B : Buffer_Type) return Natural is
   begin
      return B.Line_Breaks + 1;
   end Line_Count;

   function Row_For_Index
     (B     : Buffer_Type;
      Index : Natural) return Natural
   is
      Text  : constant String := Flat_Text (B);
      Limit : constant Natural := Natural'Min (Index, B.Last);
      Row   : Natural := 0;
      Seen  : Natural := 0;
      procedure Visit (Code : Editor.Unicode.Code_Point) is
      begin
         if Seen < Limit then
            if Editor.Unicode.Is_Newline (Code) then
               Row := Row + 1;
            end if;
            Seen := Seen + 1;
         end if;
      end Visit;
   begin
      Editor.UTF8.Decode_UTF8 (Text, Visit'Access, Editor.UTF8.Replace);
      return Row;
   end Row_For_Index;

   function Line_Start_Index
     (B   : Buffer_Type;
      Row : Natural) return Natural
   is
      Text : constant String := Flat_Text (B);
      Cur_Row : Natural := 0;
      Index   : Natural := 0;
      Result  : Natural := B.Last;
      Found   : Boolean := Row = 0;
      procedure Visit (Code : Editor.Unicode.Code_Point) is
      begin
         if Found then
            return;
         end if;

         if Editor.Unicode.Is_Newline (Code) then
            Cur_Row := Cur_Row + 1;
            if Cur_Row = Row then
               Result := Index + 1;
               Found := True;
            end if;
         end if;
         Index := Index + 1;
      end Visit;
   begin
      if Row = 0 then
         return 0;
      end if;
      Editor.UTF8.Decode_UTF8 (Text, Visit'Access, Editor.UTF8.Replace);
      return Result;
   end Line_Start_Index;

   function Line_End_Index
     (B   : Buffer_Type;
      Row : Natural) return Natural
   is
      Lines : constant Natural := Line_Count (B);
      Start : Natural := 0;
      Next  : Natural := 0;
   begin
      if Row >= Lines then
         return B.Last;
      elsif Row + 1 < Lines then
         Start := Line_Start_Index (B, Row);
         Next  := Line_Start_Index (B, Row + 1);
         if Next > Start then
            return Next - 1;
         else
            return Start;
         end if;
      else
         return B.Last;
      end if;
   end Line_End_Index;

   procedure Row_Col_For_Index
     (B     : Buffer_Type;
      Index : Natural;
      Row   : out Natural;
      Col   : out Natural)
   is
      I     : constant Natural := Natural'Min (Index, B.Last);
      Start : Natural := 0;
   begin
      Row := Row_For_Index (B, I);
      Start := Line_Start_Index (B, Row);
      if I >= Start then
         Col := I - Start;
      else
         Col := 0;
      end if;
   end Row_Col_For_Index;

   function Validate_Line_Counts (B : Buffer_Type) return Boolean is
   begin
      return Validate (B)
        and then Line_Count (B) = B.Line_Breaks + 1;
   end Validate_Line_Counts;

   procedure For_Each_Char
     (B  : Buffer_Type;
      Fn : not null access procedure (Ch : Character))
   is
      procedure Visit (Code : Editor.Unicode.Code_Point) is
         V : constant Natural := Editor.Unicode.Code_Point'Pos (Code);
      begin
         if V <= 255 then
            Fn (Character'Val (V));
         else
            Fn ('?');
         end if;
      end Visit;
   begin
      Editor.UTF8.Decode_UTF8 (Flat_Text (B), Visit'Access, Editor.UTF8.Replace);
   end For_Each_Char;

   procedure For_Each_Char_Range
     (B     : Buffer_Type;
      Start : Natural;
      Stop  : Natural;
      Fn    : not null access procedure (Ch : Character))
   is
      procedure Visit (Index : Natural; Code : Editor.Unicode.Code_Point) is
         pragma Unreferenced (Index);
         V : constant Natural := Editor.Unicode.Code_Point'Pos (Code);
      begin
         if V <= 255 then
            Fn (Character'Val (V));
         else
            Fn ('?');
         end if;
      end Visit;
   begin
      For_Each_Code_Point_Range (B, Start, Stop, Visit'Access);
   end For_Each_Char_Range;

   function Character_At
     (B     : Buffer_Type;
      Index : Natural) return Character is
      Code : constant Editor.Unicode.Code_Point := Code_Point_At (B, Index);
      V    : constant Natural := Editor.Unicode.Code_Point'Pos (Code);
   begin
      if Index >= B.Last then
         return Character'Val (0);
      elsif V <= 255 then
         return Character'Val (V);
      else
         return '?';
      end if;
   end Character_At;

   function Code_Point_At
     (B     : Buffer_Type;
      Index : Natural) return Editor.Unicode.Code_Point
   is
      Result : Editor.Unicode.Code_Point := Wide_Wide_Character'Val (0);
      Seen   : Natural := 0;
      Done   : Boolean := False;
      procedure Visit (Code : Editor.Unicode.Code_Point) is
      begin
         if Done then
            return;
         elsif Seen = Index then
            Result := Code;
            Done := True;
         else
            Seen := Seen + 1;
         end if;
      end Visit;
   begin
      if Index >= B.Last then
         return Wide_Wide_Character'Val (0);
      end if;
      Editor.UTF8.Decode_UTF8 (Flat_Text (B), Visit'Access, Editor.UTF8.Replace);
      return Result;
   end Code_Point_At;

   procedure For_Each_Code_Point_Range
     (B     : Buffer_Type;
      First : Natural;
      Last  : Natural;
      Visit : not null access procedure
        (Index : Natural;
         Code  : Editor.Unicode.Code_Point))
   is
      Safe_Last : constant Natural := Natural'Min (Last, B.Last);
      Seen      : Natural := 0;
      procedure Dispatch (Code : Editor.Unicode.Code_Point) is
      begin
         if Seen >= First and then Seen < Safe_Last then
            Visit (Seen, Code);
         end if;
         Seen := Seen + 1;
      end Dispatch;
   begin
      if First >= Safe_Last then
         return;
      end if;
      Editor.UTF8.Decode_UTF8 (Flat_Text (B), Dispatch'Access, Editor.UTF8.Replace);
   end For_Each_Code_Point_Range;

   function UTF8_Text (B : Buffer_Type) return String is
   begin
      return Flat_Text (B);
   end UTF8_Text;

   function Element
     (B     : Buffer_Type;
      Index : Natural) return Character is
   begin
      if Index = 0 or else Index > B.Last then
         return Character'Val (0);
      end if;

      return Character_At (B, Index - 1);
   end Element;

   function Tree_Height (B : Buffer_Type) return Natural is
   begin
      return Node_Height (B.Root);
   end Tree_Height;

   function Leaf_Count (B : Buffer_Type) return Natural is
   begin
      return Node_Leaf_Count (B.Root);
   end Leaf_Count;

   function Validate (B : Buffer_Type) return Boolean is
      Seen_Length : Natural := 0;
      Seen_Lines  : Natural := 0;
      Flat         : constant String := Flat_Text (B);
   begin
      return Validate_Node (B.Root, Seen_Length, Seen_Lines)
        and then Seen_Length = Flat'Length
        and then B.Last = UTF8_Code_Point_Count (Flat)
        and then Seen_Lines = B.Line_Breaks;
   end Validate;

end Text_Backend.Rope_Impl;
