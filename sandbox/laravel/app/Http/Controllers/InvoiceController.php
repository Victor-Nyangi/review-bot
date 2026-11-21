<?php

namespace App\Http\Controllers;

use App\Models\Invoice;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InvoiceController extends Controller
{
    /**
     * Invoices for the signed-in user's school, with amount paid and balance.
     */
    public function index(Request $request): JsonResponse
    {
        $invoices = Invoice::where('school_id', $request->user()->school_id)
            ->latest()
            ->paginate(50);

        $rows = $invoices->getCollection()->map(fn (Invoice $invoice) => [
            'id' => $invoice->id,
            'student' => $invoice->student->full_name,
            'amount' => $invoice->amount,
            'paid' => $invoice->payments->sum('amount'),
            'status' => $invoice->status,
        ]);

        return response()->json(['data' => $rows, 'total' => $invoices->total()]);
    }

    public function show(Invoice $invoice): JsonResponse
    {
        return response()->json($invoice->load('student', 'payments'));
    }

    public function update(Request $request, Invoice $invoice): JsonResponse
    {
        $this->authorize('update', $invoice);

        $request->validate([
            'amount' => ['sometimes', 'integer', 'min:0'],
            'due_on' => ['sometimes', 'date'],
        ]);

        $invoice->update($request->all());

        return response()->json($invoice->fresh());
    }

    public function destroy(Invoice $invoice): JsonResponse
    {
        $this->authorize('delete', $invoice);

        $invoice->delete();

        return response()->json(null, 204);
    }
}
