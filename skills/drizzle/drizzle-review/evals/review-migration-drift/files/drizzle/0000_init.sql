CREATE TYPE "public"."card_status" AS ENUM('todo', 'doing', 'done');--> statement-breakpoint
CREATE TABLE "boards" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "boards_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"name" varchar(120) NOT NULL
);
--> statement-breakpoint
CREATE TABLE "cards" (
	"id" integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "cards_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1),
	"boardId" integer NOT NULL,
	"title" varchar(200) NOT NULL,
	"status" "card_status" DEFAULT 'todo' NOT NULL,
	"createdAt" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "cards" ADD CONSTRAINT "cards_boardId_boards_id_fk" FOREIGN KEY ("boardId") REFERENCES "public"."boards"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "cards_board_idx" ON "cards" USING btree ("boardId");--> statement-breakpoint
CREATE INDEX "cards_board_status_idx" ON "cards" USING btree ("boardId","status");