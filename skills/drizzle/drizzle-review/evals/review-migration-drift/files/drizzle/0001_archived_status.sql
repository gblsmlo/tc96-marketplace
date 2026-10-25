-- added by hand during the sprint: the generator wanted to recreate the enum
ALTER TYPE "public"."card_status" ADD VALUE 'archived';
ALTER TABLE "cards" ADD COLUMN "parentId" integer REFERENCES "cards"("id");
