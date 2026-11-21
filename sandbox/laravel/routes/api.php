<?php

use App\Http\Controllers\InvoiceController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('invoices', InvoiceController::class)->only(['index', 'show', 'update', 'destroy']);
});
