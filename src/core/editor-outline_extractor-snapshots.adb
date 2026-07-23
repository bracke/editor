with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Outline;

package body Editor.Outline_Extractor.Snapshots is

   use type Editor.Outline.Outline_Item_Kind;

   Fingerprint_Modulus : constant Long_Long_Integer := 2_147_483_647;

   function Make_Snapshot
     (Text : String) return Buffer_Text_Snapshot
   is
   begin
      return
        (Text              => To_Unbounded_String (Text),
         Buffer_Label      => To_Unbounded_String ("" ),
         Snapshot_Identity =>
           (Active_Buffer_Token  => 0,
            Buffer_Revision      => 0,
            Lifecycle_Generation => 0,
            Text_Length          => Text'Length,
            Request_Token        => 0));
   end Make_Snapshot;

   function Make_Snapshot
     (Text         : String;
      Buffer_Label : String) return Buffer_Text_Snapshot
   is
   begin
      return
        (Text              => To_Unbounded_String (Text),
         Buffer_Label      => To_Unbounded_String (Buffer_Label),
         Snapshot_Identity =>
           (Active_Buffer_Token  => 0,
            Buffer_Revision      => 0,
            Lifecycle_Generation => 0,
            Text_Length          => Text'Length,
            Request_Token        => 0));
   end Make_Snapshot;

   function Make_Snapshot
     (Text               : String;
      Active_Buffer_Token : Natural;
      Buffer_Revision     : Natural;
      Lifecycle_Generation : Natural;
      Request_Token       : Natural) return Buffer_Text_Snapshot
   is
   begin
      return
        (Text              => To_Unbounded_String (Text),
         Buffer_Label      => To_Unbounded_String ("" ),
         Snapshot_Identity =>
           (Active_Buffer_Token  => Active_Buffer_Token,
            Buffer_Revision      => Buffer_Revision,
            Lifecycle_Generation => Lifecycle_Generation,
            Text_Length          => Text'Length,
            Request_Token        => Request_Token));
   end Make_Snapshot;

   function Make_Snapshot
     (Text               : String;
      Buffer_Label       : String;
      Active_Buffer_Token : Natural;
      Buffer_Revision     : Natural;
      Lifecycle_Generation : Natural;
      Request_Token       : Natural) return Buffer_Text_Snapshot
   is
   begin
      return
        (Text              => To_Unbounded_String (Text),
         Buffer_Label      => To_Unbounded_String (Buffer_Label),
         Snapshot_Identity =>
           (Active_Buffer_Token  => Active_Buffer_Token,
            Buffer_Revision      => Buffer_Revision,
            Lifecycle_Generation => Lifecycle_Generation,
            Text_Length          => Text'Length,
            Request_Token        => Request_Token));
   end Make_Snapshot;

   function Identity
     (Snapshot : Buffer_Text_Snapshot) return Editor.Outline.Outline_Snapshot_Identity
   is
   begin
      return Snapshot.Snapshot_Identity;
   end Identity;

   function Status
     (Result : Extraction_Result) return Extraction_Status
   is
   begin
      return Result.Result_Status;
   end Status;

   function Failure
     (Result : Extraction_Result) return Extraction_Failure_Kind
   is
   begin
      return Result.Failure_Kind;
   end Failure;

   function Item_Count
     (Result : Extraction_Result) return Natural
   is
   begin
      return Natural (Result.Items.Length);
   end Item_Count;

   function Identity
     (Result : Extraction_Result) return Editor.Outline.Outline_Snapshot_Identity
   is
   begin
      return Result.Result_Identity;
   end Identity;

   function Is_Success
     (Result : Extraction_Result) return Boolean
   is
   begin
      return Result.Result_Status = Extraction_Ok;
   end Is_Success;

   function Hash_Mix
     (Seed       : Natural;
      Addend     : Long_Long_Integer;
      Multiplier : Long_Long_Integer := 131) return Natural
   is
   begin
      return Natural
        ((Long_Long_Integer (Seed) * Multiplier + Addend) mod Fingerprint_Modulus);
   end Hash_Mix;

   function Hash_String
     (Seed : Natural;
      Text : String) return Natural
   is
      H : Natural := Seed;
   begin
      for C of Text loop
         H := Hash_Mix (H, Long_Long_Integer (Character'Pos (C)) + 1);
      end loop;
      return H;
   end Hash_String;

   function Fingerprint
     (Result : Extraction_Result) return Natural
   is
      H : Natural :=
        (Natural (Extraction_Status'Pos (Result.Result_Status)) + 17) * 31
        + Natural (Extraction_Failure_Kind'Pos (Result.Failure_Kind)) + 1;
   begin
      H := H mod 2_147_483_647;
      H := Hash_Mix (H, Long_Long_Integer (Item_Count (Result)) + 1);
      for Item of Result.Items loop
         H := Hash_Mix
           (H,
            Long_Long_Integer
              (Natural (Editor.Outline.Outline_Item_Kind'Pos (Item.Kind))) + 1);
         H := Hash_String (H, To_String (Item.Label));
         H := Hash_String (H, To_String (Item.Detail));
         H := Hash_Mix (H, Long_Long_Integer (Item.Depth) + 1);
         H := Hash_Mix
           (H,
            Long_Long_Integer
              (Natural (Editor.Outline.Outline_Target_Kind'Pos (Item.Target_Kind))) + 1);
         H := Hash_Mix (H, Long_Long_Integer (Item.Buffer_Token) + 1);
         H := Hash_Mix (H, Long_Long_Integer (Item.Line) + 1);
         H := Hash_Mix (H, Long_Long_Integer (Item.Column) + 1);
      end loop;
      return H;
   end Fingerprint;

end Editor.Outline_Extractor.Snapshots;
